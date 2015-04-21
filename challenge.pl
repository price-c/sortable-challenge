#!/usr/bin/perl
use strict;
use warnings;
use JSON;

@ARGV == 3 or die("use: perl challenge.pl <products> <listings> <results>\n");

my $prod_file = $ARGV[0];
my $list_file = $ARGV[1];
my $out_file = $ARGV[2];


# store the results as a dictionary, where the keys are the
# product_name fields (assumed to be unique) and the values
# are arrays of listings associated with that product
# this section initializes the dictionary
my %results;

open PRODUCTS, $prod_file or die("could not open products file\n");
foreach my $prod_json (<PRODUCTS>){
    my $prod = decode_json($prod_json);
    $results{$prod->{product_name}} = ();
}# foreach prod_json in PRODUCTS
close PRODUCTS;


# 'each listing can be assigned to at most one product'
# without making any assumptions about the product file,
# we must loop over the listings THEN the products, instead
# of the other way around (the easy way)
open LISTINGS, $list_file or die("could not open listings file\n");
foreach my $listing_json (<LISTINGS>){

    my $listing = decode_json($listing_json);
    my $title = $listing->{title};
    my $list_mfgr = $listing->{manufacturer};

    # find which product (if any) to assign the listing to
    open PRODUCTS, $prod_file or die("could not open products file\n");
    foreach my $prod_json (<PRODUCTS>){

	my $prod = decode_json($prod_json);
	my $prod_name = $prod->{product_name};
	my $mfgr = $prod->{manufacturer};
	my $model = $prod->{model};
	my $family = $prod->{family};

	# test for a match. the criteria are as follows:
	# 1. product mfgr is contained in listing mfgr or vice versa,
	# 2. (subj. to 1.) product mfgr and model are contained in
	#    listing title, and
	# 3. (subj. to 2. and if applicable) product family is contained
	#    in listing title.
	if ($list_mfgr =~ /\b$mfgr\b/i || $mfgr =~ /\b$list_mfgr\b/i){
	    if ($title =~ /\b$mfgr\b/i && $title =~ /\b$model\b/i){
		do {
		    push @{ $results{$prod_name} }, $listing;
		    #break the loop, since the listing is associated
		    last;
		} unless $family and $title !~ /\b$family\b/i; #criterion 3
	    }# match for criterion 2
	}# match for criterion 1
    }# foreach prod_json in PRODUCTS
    close PRODUCTS;
}# foreach listing_json in LISTINGS
close LISTINGS;

# now just print out the results
open OUT, '>', $out_file or die("could not open output file\n");
foreach my $key ( keys %results ) {
    print OUT '{"product_name":"' . $key . '","listings":';

    # encode_json does not like empty arrays
    if ($results{$key}){
	print OUT encode_json($results{$key});
    }
    else {
	print OUT '[]';
    }

    print OUT "}\n";
}
close OUT;
