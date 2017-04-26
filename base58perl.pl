#!/usr/bin/perl
use warnings;
use strict;

# Converts a hexadecimal string into a Bitcoin-base58 string.
# Adapted from http://lenschulwitz.com/b58/base58perl.txt 
# Validate with http://lenschulwitz.com/base58
# Code validates, decodes, and encodes bitcoin addresses.
# Author: Len Schulwitz + friends at http://rosettacode.org/wiki/Bitcoin/address_validation

my $isList = ($#ARGV>=0 && $ARGV[0] eq "string")? 0: 1; # 'checksum' (dafault) or 'string'

#The base58 characters used by Bitcoin.
my @b58 = qw{
      1 2 3 4 5 6 7 8 9
    A B C D E F G H   J K L M N   P Q R S T U V W X Y Z
    a b c d e f g h i j k   m n o p q r s t u v w x y z
};
#Used to decode base58 encoded bitcoin addresses (i.e. standard bitcoin addresses).
my %b58 = map { $b58[$_] => $_ } 0 .. 57;
#The reverse hash, used to base58 encode addresses represented as binary decimals.
my %reverseb58 = reverse %b58;

#Encodes a base58 encoded bitcoin address from array of binary decimals.
sub base58 {
	my @binary_address_to_encode = @{$_[0]};
	die "Subroutine base58 needs binary decimal array to encode!\n" unless @binary_address_to_encode;
	#This adds slightly more processing than is necessary, but will ensure all bytes are encoded.
	my $base58_encoded_array_size = 2 * scalar @binary_address_to_encode;
	my @base58_encoded_address;
	#Counts number of leading 0's in decimal address.
	my $leading_zeroes = length $1 if join('', @binary_address_to_encode) =~ /^(0*)/;
	#Cycle through each binary decimal character, encoding to Base58.
	for my $dec_char ( @binary_address_to_encode ) {
		#Cycle through each index (i.e. base58 encoded character) of array holding base58 encoded result. 
	        for (my $encoded_character_index = $base58_encoded_array_size; $encoded_character_index--; ) {
			#See Satoshi's base58.cpp code for details.
			$dec_char += 256 * ($base58_encoded_address[$encoded_character_index] // 0);
			$base58_encoded_address[$encoded_character_index] = $dec_char % 58;
			$dec_char /= 58;
		}
	}
	#Generate encoded address with extra leading ones
	my $encoded_address_with_leading_1s = join('', map { $reverseb58{$_} } @base58_encoded_address);
	#Truncate address so that the number of leading zero bytes in the binary address are equal to the number of leading ones in the base58 encoded address.
	if ($encoded_address_with_leading_1s =~ /(1{$leading_zeroes}[^1].*)/){
		#Return matching base58 encoded bitcoin address.
		return $1;
	}
	#If encoding only zero bytes...
	elsif ($encoded_address_with_leading_1s =~ /(1{$leading_zeroes})/){
		return $1;
	}
	else{
		die "Unexpected error in subroutine base58!\n";
	}
}

#Decodes bitcoin address from its Base58 encoding into an array of binary decimals. 
sub unbase58 {
	my $bitcoin_address = $_[0];
	die "Subroutine unbase58 needs base58 encoded bitcoin address to decode!\n" unless defined $bitcoin_address;
	die "Cannot Decode! Invalid Base58 Character(s)!\n" unless $bitcoin_address =~ /^[1-9A-HJ-NP-Za-km-z]*$/;
	#This is overkill, but it allows for plenty of room to store decoded bytes.
	my $decoded_array_size = length($bitcoin_address); 
	my @decoded_binary_address; #Array that will hold bytes of Base58 decoded address.
	#Counts number of leading 1's in bitcoin address.
	my $leading_ones = length($1) if $bitcoin_address =~ /^(1*)/;
	#Cycle through each character of address, decoding from Base58.
	for my $b58_char ( map { $b58{$_} } $bitcoin_address =~ /./g ) {
		#Cycle through each index (i.e decimal byte) of array holding base58 decoded result.
		for (my $decoded_byte_index = $decoded_array_size; $decoded_byte_index--; ) {
			#See Satoshi's base58.cpp code for encoding details.
			$b58_char += 58 * ($decoded_binary_address[$decoded_byte_index] // 0);
			$decoded_binary_address[$decoded_byte_index] = $b58_char % 256;
			$b58_char /= 256;
		}
	}
	#Counts number of leading zeroes in decoded binary decimal array.
	my $leading_zeroes = length($1) if join('', @decoded_binary_address) =~ /^(0*)/;
	#If leading zeroes of decoded address don't equal leading ones of encoded address, trim them off.
	for (1 .. $leading_zeroes - $leading_ones){
		shift @decoded_binary_address;
	}
	return @decoded_binary_address;
}

#Converts standard bitcoin address to binary form as hexadecimal.
sub decodebase58tohex {
	#Takes standard base58 encoded bitcoin address
	my $std_bitcoin_address = $_[0];
	die "Subroutine decodebase58tohex needs base58 bitcoin address as input!\n" unless (defined $std_bitcoin_address and length $std_bitcoin_address != 0);
	#Base58 decodes address to binary decimal form.
	my @decoded_binary_address = unbase58($std_bitcoin_address);
	#Converts binary to hexadecimal.
	my $hex_binary_address = '';
	foreach(@decoded_binary_address){
		$hex_binary_address .= sprintf("%02X", $_);
	}
	return $hex_binary_address;
}

#Converts binary bitcoin address input as hexadecimal to standard Base58 address.
sub encodebase58fromhex {
	#Takes hexadecimal representation of 25-byte binary address.
	my $hex_binary_address = $_[0];
	die "Subroutine encodebase58fromhex needs binary address represented with hex characters as input!" unless (defined $hex_binary_address and length $hex_binary_address != 0);
	die "Cannot Encode! Invalid Hexadecimal Character(s)!\n" unless $hex_binary_address =~ /^[a-f0-9]*$/i;
	#Converts to binary decimal form.
	my @binary_address_to_encode = $hex_binary_address =~ /../g;
	for( 0 .. scalar(@binary_address_to_encode)-1 ){
		$binary_address_to_encode[$_] = hex($binary_address_to_encode[$_]);
	}
	#Base58 encodes and returns standard form bitcoin address.
	my $std_bitcoin_address = base58(\@binary_address_to_encode);
	return $std_bitcoin_address;
}

$shafilename = "sha3-256sum.b58btc.txt";

if ($isList) {
	print STDERR "\n-- construindo verificadores SHA3... aguarde.\n";
	my $OUT = '';
	my @cksums= `sha3sum -a 256 * | grep -v sha3-256sum`;
	chomp @cksums;
	foreach(@cksums) {  # old <STDIN>
		if (/^([a-fA-F0-9]+)\s+(.+)$/) {
			my $p='';
			my $enc = encodebase58fromhex($1);
			my $l = 44-length($enc);
			if ($l>0) {$p = '1' x $l;}
			$OUT .= "$p$enc  $2\n";
		} else { print "ERROR: wrong input line = '$_'\n";}
	}
	open my $fp, '>', $shafilename or die $!;
	print $fp $OUT;
	print STDERR "\n-- arquivo '$shafilename' gerado com sucesso, confira\n";

} else {
	my $str = do { local $/; <STDIN> };
	my $reencoded_base58 = encodebase58fromhex($str);
	print "\nRe-encoded back to Base58 is: $reencoded_base58\n\n";
}



