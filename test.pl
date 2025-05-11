#!/usr/bin/env perl
use 5.020;
use utf8;
use warnings;
use autodie;
use feature qw/signatures postderef/;
no warnings qw/experimental::postderef/;

use Test::More;
use Mojo::Util;
use DateTime;

require './main.pl';

{
    my $feed = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>极客公园</title>
    <description>极客公园</description>
    <link>http://mainssl.geekpark.net/rss.rss</link>
    <image>
      <url>https://imgslim.geekpark.net/images/GeekPart-blacklogo.png</url>
      <title>极客公园</title>
      <link>http://www.geekpark.net</link>
    </image>
    <item>
      <title>
        <![CDATA[雷军隔月首发声：创立小米以来最难的日子；Altman向马斯克服软「AGI比恩怨重要」；酷玩等明星抗议AI滥用]]>
      </title>
      <link>http://www.geekpark.net/news/349136</link>
      <description>
        <![CDATA[<p style="text-align: center;"><img src="https://imgslim.geekpark.net/uploads/image/file/2e/b4/2eb4e0d7cb393c60d676ce5906711987.png" /></p>
<h2>雷军时隔月余首度发声：系小米创办以来最艰难的一段时间，感谢大家的关心和支持</h2>
<p>基德隆的修正案将于下周一在上议院投票，但政府已表示反对，认为当前的版权法咨询程序应是调整版权法的正确途径。（来源：IT 之家）</p>
<p>&nbsp;</p>]]>
      </description>
      <source>极客公园</source>
      <pubDate>Sun, 11 May 2025 08:03:07 +0800</pubDate>
    </item>
    <item>
      <title>
        <![CDATA[中国汽车，开始「量产博世」]]>
      </title>
      <link>http://www.geekpark.net/news/349134</link>
      <description>
        <![CDATA[<p style="text-align: left;">2025年的上海车展，没有了往日的「喧嚣」。</p>
<p style="text-align: left;">目前来看，供应商特别是智能解决方案供应商，从幕后走到台前，是汽车产业转向智能化的必然。曾经毋庸置疑的「链主」&mdash;&mdash;车企的核心价值正在向那些掌握电动化、智能化关键技术的供应商倾斜。因此，未来的汽车竞争，已远不止于品牌之间的单维较量，而是一场多维度的综合博弈：既是对核心供应链的掌握，也在于对关键技术生态的选择。谁能在新价值链中占据关键位置，谁就能拿到通向未来的钥匙。</p>]]>
      </description>
      <source>极客公园</source>
      <pubDate>Sat, 10 May 2025 08:34:00 +0800</pubDate>
    </item>
  </channel>
</rss>
EOF

    my $expected = [
        {
            source => '极客公园',
            title => '雷军隔月首发声：创立小米以来最难的日子；Altman向马斯克服软「AGI比恩怨重要」；酷玩等明星抗议AI滥用',
            link => 'http://www.geekpark.net/news/349136',
            abstract => Mojo::Util::trim(<<'EOF'),
雷军时隔月余首度发声：系小米创办以来最艰难的一段时间，感谢大家的关心和支持
基德隆的修正案将于下周一在上议院投票，但政府已表示反对，认为当前的版权法咨询程序应是调整版权法的正确途径。（来源：IT 之家）
EOF
            description_text => Mojo::Util::trim(<<'EOF'),
雷军时隔月余首度发声：系小米创办以来最艰难的一段时间，感谢大家的关心和支持
基德隆的修正案将于下周一在上议院投票，但政府已表示反对，认为当前的版权法咨询程序应是调整版权法的正确途径。（来源：IT 之家）
EOF
            description => Mojo::Util::trim(<<'EOF'),
<p style="text-align: center;"><img src="https://imgslim.geekpark.net/uploads/image/file/2e/b4/2eb4e0d7cb393c60d676ce5906711987.png" /></p>
<h2>雷军时隔月余首度发声：系小米创办以来最艰难的一段时间，感谢大家的关心和支持</h2>
<p>基德隆的修正案将于下周一在上议院投票，但政府已表示反对，认为当前的版权法咨询程序应是调整版权法的正确途径。（来源：IT 之家）</p>
<p>&nbsp;</p>
EOF
            pub_date => DateTime->from_epoch(
                epoch => 1746921787,
                time_zone => 'Asia/Shanghai',
            ),
        },
        {
            title => '中国汽车，开始「量产博世」',
            link => 'http://www.geekpark.net/news/349134',
            abstract => Mojo::Util::trim(<<'EOF'),
2025年的上海车展，没有了往日的「喧嚣」。
目前来看，供应商特别是智能解决方案供应商，从幕后走到台前，是汽车产业转向智能化的必然。曾经毋庸置疑的「链主」——车企的核心价值正在向那些掌握电动化、智能化关键技术的供应商倾斜。因此，未来的汽车竞争，已远不止于品牌之间的单维较量，而是一场多维度的综合博弈：既是对核心供应链的掌握，也在于对关键技术生态的选择。谁能在新价值链中占据关键位置，谁就能拿到通向未来的钥匙。
EOF
            description_text => Mojo::Util::trim(<<'EOF'),
2025年的上海车展，没有了往日的「喧嚣」。
目前来看，供应商特别是智能解决方案供应商，从幕后走到台前，是汽车产业转向智能化的必然。曾经毋庸置疑的「链主」——车企的核心价值正在向那些掌握电动化、智能化关键技术的供应商倾斜。因此，未来的汽车竞争，已远不止于品牌之间的单维较量，而是一场多维度的综合博弈：既是对核心供应链的掌握，也在于对关键技术生态的选择。谁能在新价值链中占据关键位置，谁就能拿到通向未来的钥匙。
EOF
            description => Mojo::Util::trim(<<'EOF'),
<p style="text-align: left;">2025年的上海车展，没有了往日的「喧嚣」。</p>
<p style="text-align: left;">目前来看，供应商特别是智能解决方案供应商，从幕后走到台前，是汽车产业转向智能化的必然。曾经毋庸置疑的「链主」&mdash;&mdash;车企的核心价值正在向那些掌握电动化、智能化关键技术的供应商倾斜。因此，未来的汽车竞争，已远不止于品牌之间的单维较量，而是一场多维度的综合博弈：既是对核心供应链的掌握，也在于对关键技术生态的选择。谁能在新价值链中占据关键位置，谁就能拿到通向未来的钥匙。</p>
EOF
            source => '极客公园',
            pub_date => DateTime->from_epoch(
                epoch => 1746837240,
                time_zone => 'Asia/Shanghai',
            ),
        }
    ];

    my $result = parse_feed($feed);
    is_deeply($result, $expected, 'parse feed');
}

{
    my $dt1 = parse_date('Sun, 11 May 2025 08:03:07 +0800');
    my $dt2 = parse_date('Sun, 11 May 2025 06:11:28 GMT');
    my $duration = $dt2 - $dt1;
    is($duration->hours, 6, 'parse date');
}

done_testing;
