#!/usr/bin/env perl
use 5.020;
use utf8;
use warnings;
use autodie;
use feature qw/signatures postderef/;
no warnings qw/experimental::postderef/;

use Mojo::DOM;
use Mojo::Util;
use DateTime;
use DateTime::Format::HTTP;
use Mojo::Log;
use Mojo::UserAgent;
use Lingua::ZH::Jieba;

use Env qw/
$ABSTRACT_MAX_LEN
$TIMESPAN_HOURS
$RSS_LINK_FILE
$TIME_ZONE
$ONEBOT_ENDPOINT
$ONEBOT_TOKEN
$SELF_ID
@GROUP_IDS
/;

my $LOCAL_TIME_ZONE = $TIME_ZONE // DateTime::TimeZone->new(name => 'local');
$ABSTRACT_MAX_LEN //= 180;
$TIMESPAN_HOURS //= 3;
die unless defined $SELF_ID;
die unless defined $ONEBOT_ENDPOINT;
die unless defined $ONEBOT_TOKEN;
die unless @GROUP_IDS;
die unless defined $RSS_LINK_FILE;

my $LOG = Mojo::Log->new;
my $UA = Mojo::UserAgent->new;
$UA->proxy->detect;
my $JIEBA = Lingua::ZH::Jieba->new();

sub tiebafy ($url) {
    my $escaped = Mojo::Util::url_escape $url, '^A';
    "https://tieba.baidu.com/mo/q/checkurl?url=$escaped"
}

sub make_censored ($text) {
    join "\x{200B}", split '', $text
}

sub parse_date ($string) {
    DateTime::Format::HTTP->parse_datetime($string)
}

sub flatten_html ($html) {
    Mojo::DOM->new($html)->all_text;
}

sub make_abstract ($text) {
    my $abstract = '';
    for my $sentence (split /\b{sb}/, $text) {
        my $extended = $abstract . $sentence;
        if (length($extended) > $ABSTRACT_MAX_LEN) {
            return $abstract;
        }
        $abstract = $extended;
    }
    return $abstract;
}

sub parse_feed_item ($item_dom, $channel_title) {
    my $description = eval {
        Mojo::Util::trim($item_dom->at('description')->text)
    } // Mojo::Util::trim($item_dom->at('content\:encoded')->text);
    my $description_text = Mojo::Util::trim(flatten_html($description));
    my $title = Mojo::Util::trim($item_dom->at('title')->text);
    my $link = eval { $item_dom->at('link')->text } // '[NO LINK]';
    my $source = eval { $item_dom->at('source')->text } // $channel_title;
    my $pub_date = eval {
        parse_date($item_dom->at('pubDate')->text)
    } // eval {
        parse_date($item_dom->at('pubdate')->text)
    } // parse_date($item_dom->at('dc\:date')->text);
    {
        title => $title,
        link => $link,
        abstract => make_abstract($description_text),
        description => $description,
        description_text => $description_text,
        source => $source,
        pub_date => $pub_date,
    }
}

sub parse_feed ($content) {
    $content = Mojo::Util::trim($content);
    $content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>$content" unless $content =~ /^\Q<?xml version\E/;
    my $dom = Mojo::DOM->new($content);
    my $channel_title = Mojo::Util::trim($dom->at('title')->text);
    my @result;
    for my $item ($dom->find('item')->@*) {
        my $parsed = eval { parse_feed_item($item, $channel_title) };
        if ($@) {
            $LOG->warn("failed to parse item: $@, $item");
        } else {
            push @result, $parsed;
        }
    }
    \@result;
}

sub fetch_all_items (@links) {
    my @items;
    my $cnt = 0;
    my $tot = @links;
    for my $link (@links) {
        $cnt += 1;
        $LOG->info("fetching ($cnt/$tot): $link");
        eval {
            my $resp = $UA->get($link);
            my $result = $resp->result;
            die "failed to fetch $link: " . $result->code unless $result->is_success;
            my $content = $result->text;
            utf8::decode($content) unless utf8::is_utf8($content);
            push @items, @{ parse_feed($content) };
        };
        $LOG->warn("failed to fetch feed($link): $@") if $@;
    }
    @items;
}

sub render_item ($item) {
    my $date = $item->{pub_date}->clone;
    $date->set_time_zone($LOCAL_TIME_ZONE);
    my $link = $item->{link} ? tiebafy($item->{link}) : '';
    my $source = make_censored($item->{source});
    my $title = make_censored($item->{title});
    my $pump_elephant = make_censored($item->{abstract});

    my $keywords = join " ", map {
        my ($word, $score) = @$_;
        sprintf "#%s(%.2f)", $word, $score,
    } @{$JIEBA->extractor->extract($item->{description_text}, 5)};

    my $rendered = Mojo::Util::trim(<<"EOF");
【$source】$date
$title
$link

$pump_elephant

$keywords
EOF
}

sub content_ok ($content) {
    1
}

sub render_chouxiang (@recent) {
    my $cnt = 0;
    my $message = join "\n",
    grep {
        content_ok($_)
    } map {
        $cnt += 1;
        my $title = make_censored($_->{title});
        "[$cnt] $title"
    } @recent;

    my $rendered = Mojo::Util::trim(<<EOF)
新闻抽象（Pump Elephant）：

$message
EOF
}

sub main {
    my $now = DateTime->now;
    my $span = DateTime::Duration->new( hours => $TIMESPAN_HOURS );
    my @links = split "\n", Mojo::File::path($RSS_LINK_FILE)->slurp;
    my @items = fetch_all_items(@links);

    $LOG->info("# items got: " . scalar(@items));

    my @recent = grep { defined($_->{pub_date}) and $_->{pub_date} + $span > $now } @items;
    my @contents = grep { content_ok($_) } map { render_item($_) } @recent;

    my $chouxiang = render_chouxiang(@recent);

    $LOG->info("# items to push: " . scalar(@contents));

    my $node_payload = [
        {
            type => 'node',
            data => {
                user_id => $SELF_ID,
                nickname => '不学新闻学导致的',
                content => [
                    {
                        type => 'text',
                        data => {
                            text => $chouxiang,
                        }
                    }
                ]
            }
        },
        map {
            {
                type => 'node',
                data => {
                    user_id => $SELF_ID,
                    nickname => '学新闻学的',
                    content => [
                        {
                            type => 'text',
                            data => {
                                text => $_
                            }
                        }

                    ]
                },
            }
        } @contents
    ];

    for my $group_id (@GROUP_IDS) {
        my $send_payload = {
            group_id => $group_id,
            messages => $node_payload,
        };
        $UA->post(
            "$ONEBOT_ENDPOINT/send_group_forward_msg" => {
                Authorization => "Bearer $ONEBOT_TOKEN",
            },
            json => $send_payload,
        )
    }
}

main unless caller;
