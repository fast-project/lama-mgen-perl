#!/usr/bin/perl
#
# Generate 2D5P stencil files for Lama CG solver
#

$prefix = "m";
$sx = 50;
$sy = 50;

if (($ARGV[0] eq "") || ($ARGV[0] eq "-h") || ($ARGV[0] eq "--help")) {
    print "Usage: gen2D <file> [<dimX> [<dimY>]]\n";
    exit;
}

$prefix = $ARGV[0];

if ($ARGV[1] ne "") {
    $sx = $ARGV[1];
    $sy = $sx;
}

if ($ARGV[2] ne "") {
    $sy = $ARGV[2];
}

print "Generating 2D-5P Stencil matrix '".$prefix."'";
print ", dimensions XY ".$sx." x ".$sy."\n";

$steps = 10;
if ($sx * $sy < 1000000) { $steps = 2; }

sub index2D
{
    my ($xx, $yy) = @_;
    #print "Called index2D x = ".$xx.", y = ".$yy."\n";
    return $yy * $sx + $xx +1;    
}


# AMG part
print "Writing '".$prefix.".amg':\n";
open($out, '>:raw', $prefix . ".amg") or die "Unable to write amg";

# part 1: row offsets
print " Row offsets ...\n";
$off = 1;
foreach $y (0 .. ($sy-1)) {
    foreach $x (0 .. ($sx-1)) {
	$p = 5;
	if (($y == 0) || ($y == $sy-1)) { $p--; }
	if (($x == 0) || ($x == $sy-1)) { $p--; }
	#print "(".$x."/".$y.") : ".$p."\n";

	# write 4-byte little-endian unsigned int
	print $out pack('I', $off);
	$off += $p;
    }
    if ($y % ($sy/$steps) == 0) {
	printf("   %.0f %% ...\n", (100.0 * $y)/$sy);
    }
}
print $out pack('I', $off);
print "   last offset: ".$off."\n";

# part 2: column offsets
print " Column offsets ...\n";
foreach $y (0 .. ($sy-1)) {
    foreach $x (0 .. ($sx-1)) {
	# first center
	print $out pack('I', index2D($x,$y));
	if ($y>0) {
	    # point above
	    print $out pack('I', index2D($x,$y-1));
	}
	if ($x>0) {
	    # point left
	    print $out pack('I', index2D($x-1,$y));
	}
	if ($x < $sx-1) {
	    # point right
	    print $out pack('I', index2D($x+1,$y));
	}
	if ($y < $sy-1) {
	    # point below
	    print $out pack('I', index2D($x,$y+1));
	}
    }
    if ($y % ($sy/$steps) == 0) {
	printf("   %.0f %% ...\n", (100.0 * $y)/$sy);
    }
}

#print $out pack('dddd', 4.0, -1.0, -1.0, 4.0);

# part 3: values
print " Values ...\n";
foreach $y (0 .. ($sy-1)) {
    foreach $x (0 .. ($sx-1)) {
	# first center
	print $out pack('d', 4.0);
	if ($y>0) {
	    # point above
	    print $out pack('d', -1.0);
	}
	if ($x>0) {
	    # point left
	    print $out pack('d', -1.0);
	}
	if ($x < $sx-1) {
	    # point right
	    print $out pack('d', -1.0);	    
	}
	if ($y < $sy-1) {
	    # point below
	    print $out pack('d', -1.0);
	}
    }
    if ($y % ($sy/$steps) == 0) {
	printf("   %.0f %% ...\n", (100.0 * $y)/$sy);
    }
}
close $out;

# VEC part
print "Writing '".$prefix.".vec' ...\n";
open($out, '>:raw', $prefix . ".vec") or die "Unable to write vec";

foreach $y (0 .. ($sy-1)) {
    foreach $x (0 .. ($sx-1)) {
	$v = 0.0;
	if (($x == 0) || ($x == $sx-1)) { $v += 1.0; }
	if (($y == 0) || ($y == $sy-1)) { $v += 1.0; }
	print $out pack('d', $v);
    }
}
close $out;

# FRM
print "Writing '".$prefix.".frm' ...\n";
open($out, '>:raw', $prefix . ".frm") or die "Unable to write frm";
print $out "b \t4\n\t\t".($off - $sy - 1)."\t".($sx*$sy)."\t22\t1\t0";
close $out;

# FRV
print "Writing '".$prefix.".frv' ...\n";
open($out, '>:raw', $prefix . ".frv") or die "Unable to write frv";
print $out "b\n".($sx*$sy)."\n8";
close $out;
