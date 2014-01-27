
use strict;
use warnings;

use Bio::EnsEMBL::Expression;
use Bio::EnsEMBL::Analysis;

use Bio::EnsEMBL::Test::TestUtils;

our $verbose = 0; #set to 1 to turn on debug printouts

use Test::More;

use Bio::EnsEMBL::Test::TestUtils;

#
# test constructor
#

my $name     = 'testname';
my $desc     = 'testdesc';
my $ontology = 'testontology';
my $value    = 'testval';
my $value_type = 'count';
my $analysis = Bio::EnsEMBL::Analysis->new(-LOGIC_NAME => 'testana');

my $tissue = Bio::EnsEMBL::Expression->new
  (-NAME => $name,
   -DESCRIPTION => $desc,
   -ONTOLOGY => $ontology,
   -ANALYSIS => $analysis,
   -VALUE_TYPE => $value_type,
   -VALUE => $value);

is($tissue->name(), $name, "Correct tissue name is set");
is($tissue->description(), $desc, "Correct description is set");
is($tissue->ontology(), $ontology, "Correct ontology is set");
is($tissue->value_type(), $value_type, "Correct value_type is set");
is($tissue->value(), $value, "Correct value is set");

#
# test getter/setters
#
ok(test_getter_setter($tissue, 'name', 'newname'));
ok(test_getter_setter($tissue, 'ontology', 'newontology'));
ok(test_getter_setter($tissue, 'description', 'newdesc'));
ok(test_getter_setter($tissue, 'value', 'newvalue'));
ok(test_getter_setter($tissue, 'value_type', 'RPKM'));

done_testing();
