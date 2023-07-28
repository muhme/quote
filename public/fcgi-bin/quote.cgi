#!/usr/bin/perl -w
#
# quote.pl
# hlu, Sep/17/2006 - June/10/2023

use strict;
use CGI::Fast;
use DBI;

my $DSN = $ENV{'QUOTE_DSN'}; # e.g. 'DBI:mysql:quote_production:localhost';
my $READ_USER = $ENV{'QUOTE_READ_USER'}; # e.g. 'quote_production_read';
my $USER_PASSWORD = $ENV{'QUOTE_READ_PASSWORD'};


# Convert the four special characters ', ", ( and ). And remove all new lines and returns.
# This is needed if we have to generate JavaScript code and to prevent incorrect syntax.
sub convert_special_chars($) {
    my $array_pointer = shift;

    foreach (@{$array_pointer}) {
        $_ =~ s/\'/\&#39;/g;
        $_ =~ s/\"/\&#34;/g;
        $_ =~ s/\(/\&#40;/g;
        $_ =~ s/\)/\&#41;/g;
        $_ =~ s/\n//g;
        $_ =~ s/\r//g;
    }
    return
}

# link quotation if $id set
sub linkIt($$$) {
    my $id = shift;
    my $quotation = shift;
    my $window = shift;

    $quotation = "<a href=\"https://www.zitat-service.de/quotations/$id\" target=\"" . $window . "\">$quotation</a>" if $id;

    return $quotation;
}

# check a string is defined and has a lenght greater 0
sub isGiven($) {
    my $string = shift;

    return (defined $string and ( length($string) > 0 ))
}

# returned "", "firstname", "name" or "firstname name"  for authors name
# with hyperlink if author_link isGiven
# added by ", source" if given and source hyperlink
sub authorAndSource($$$$$$) {
    next unless defined $_; # skip the loop if $_ is not defined
    my $firstname = shift;
    my $name = shift;
    my $author_link = shift;
    my $source = shift;
    my $source_link = shift;
    my $window = shift;

    my $ret = "";
    if (isGiven ($firstname)) {
        $ret .= $firstname;
        $ret .= " " if isGiven($name);
    }
    $ret .= $name if isGiven $name;

    $ret = "<a href=\"$author_link\" target=\"" . $window . "\">$ret</a>" if isGiven $author_link;

    $source = "<a href=\"$source_link\" target=\"" . $window . "\">$source</a>" if isGiven $source_link;

    if (isGiven $source) {
        if ($ret eq "Unbekannt") {
            # prevent 'Unbekannt' author if source is given, like "Sprichwort aus China"
            $ret = $source
        } else {
            $ret .= ", $source"
        }
    }

    return $ret;
}

# main
#
# Parameter JavaScript is only used for older Joomla zitat-service module versions,
# starting with version 1.2, December 2010 JavaScriptFunction is used. JavaScript
# parameter could be removed some years later (check htaccess for usage before).
{

  while (my $cgi = CGI::Fast->new) {

    my $encoding = $cgi->param('encoding'); # useful are ISO-8859-1 and UTF-8
    my $category = $cgi->param('category');
    my $style = $cgi->param('style');
    my $user = $cgi->param('user');
    my $author = $cgi->param('author');
    my $content_only = $cgi->param('content_only'); # not set, "true", "JavaScript" or "JavaScriptFunction"
    my $window = $cgi->param('window');
    my ($sql, $id, $quotation, $source, $source_link, $firstname, $name, $author_link);
    my  $dbh = DBI->connect($DSN, $READ_USER, $USER_PASSWORD);

    # default is parent window, but you can give e.g. window=quote to open links in a new window
    $window = "_parent" unless $window;

    # default encoding is iso-8859-1
    $encoding = "ISO-8859-1" unless $encoding;

    if ($dbh) {

        my $charset = $encoding;
        $charset = "utf8" if $charset eq "UTF-8";
        $charset = "latin1" if $charset eq "ISO-8859-1";

        $dbh->do("SET character_set_results=\"$charset\"");

        $sql = "SELECT q.id, q.quotation, q.source, q.source_link, f_mst.value, n_mst.value, l_mst.value FROM quotations q, authors a, ";
        $sql .= " mobility_string_translations f_mst, mobility_string_translations n_mst, mobility_string_translations l_mst ";
        $sql .= ", categories_quotations cq, categories c, mobility_string_translations mst" if $category;
        $sql .= ", users u" if $user;
        $sql .= " WHERE q.author_id = a.id and ";
        $sql .= " f_mst.locale = 'de' and f_mst.translatable_type = 'Author' and f_mst.key = 'firstname' and f_mst.translatable_id = a.id AND";
        $sql .= " n_mst.locale = 'de' and n_mst.translatable_type = 'Author' and n_mst.key = 'name' and n_mst.translatable_id = a.id AND ";
        $sql .= " l_mst.locale = 'de' and l_mst.translatable_type = 'Author' and l_mst.key = 'link' and l_mst.translatable_id = a.id ";
        if ($user) {
            $sql .= " AND u.login = ? AND u.id = q.user_id";
        } else {
            $sql .= " AND q.public = 1 AND q.author_id = a.id";
        }

        if ($category) {
            $sql .= " AND cq.quotation_id = q.id
            AND cq.category_id = c.id
            AND cq.category_id = mst.translatable_id
            AND mst.locale = 'de'
            AND mst.translatable_type = 'Category'
            AND mst.value = ?";
        }
        $sql .= " and n_mst.value = ?" if $author;
        $sql .= " ORDER BY rand() LIMIT 1";
        my @statement = ($sql);
        push (@statement, undef); # unused \%attr
        push (@statement, $user) if $user;
        push (@statement, $category) if $category;
        push (@statement, $author) if $author;
# print "\n\nstatement=\"@statement\"\n\n";
        my @db_array = $dbh->selectrow_array(@statement);
        convert_special_chars(\@db_array);
        ($id, $quotation, $source, $source_link, $firstname, $name, $author_link) = @db_array;
        unless ($quotation) {
            if ($dbh->errstr()) {
               $quotation = "Datenbankfehler: " . $dbh->errstr();
            } elsif ($category or $user or $author) {
                $quotation = "Keine Zitate f&uuml;r:";
                $quotation .= " Kategorie \"$category\"" if $category;
                $quotation .= " Benutzer \"$user\"" if $user;
                $quotation .= " Author \"$author\"" if $author;
            } else {
                $quotation = "Kein Zitat gefunden!";
            }
        }
    } else {
        # no connection to $DSN
        $quotation = "Konnte keine Verbindung aufbauen zu $DSN";
    }

    print $cgi->header(-charset=>$encoding, -access_control_allow_origin => '*');
    unless ($content_only) {
        if ($style) {
            print $cgi->start_html(-encoding=>$encoding, -lang=>'de',-title=>'www.zitat-service.de',-style=>{'src'=>$style});
        } else {
            print $cgi->start_html(-encoding=>$encoding, -lang=>'de',-title=>'www.zitat-service.de'),
        }
    }
    print "document.write('" if $content_only and $content_only eq 'JavaScript';
    print "function quote() { return '" if $content_only and $content_only eq 'JavaScriptFunction';
    print "<div class=\"quote\">" unless $content_only and $content_only eq 'JavaScriptFunction';
    print "<div class=\"quotation\">";
    print linkIt($id, $quotation, $window);
    print "</div><div class=\"source\">";
    print authorAndSource($firstname, $name, $author_link, $source, $source_link, $window);
    print "</div>";
    print "</div>" unless $content_only and $content_only eq 'JavaScriptFunction';
    print "');" if $content_only and $content_only eq 'JavaScript';
    print "';}" if $content_only and $content_only eq 'JavaScriptFunction';
    print $cgi->end_html() unless $content_only;

    $dbh->disconnect if $dbh;
  }
}
