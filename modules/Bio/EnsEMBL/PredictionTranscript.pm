=head1 LICENSE

  Copyright (c) 1999-2009 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

    http://www.ensembl.org/info/about/code_licence.html

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <ensembl-dev@ebi.ac.uk>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=cut

=head1 NAME

PredictionTranscript

=head1 SYNOPSIS

=head1 DESCRIPTION

Container for single transcript ab initio gene prediction such as
GenScan or SNAP. Is directly storable/retrievable in Ensembl using
PredictionTranscriptAdaptor.

Creation:

  my $tran = new Bio::EnsEMBL::PredictionTranscript();
  $tran->add_Exon($pred_exon);

  my $tran =
    new Bio::EnsEMBL::PredictionTranscript( -EXONS => @pred_exons );

Manipulation:

  # Returns an array of PredictionExon objects
  my @pred_exons = @{ $tran->get_all_Exons };

  # Returns the peptide translation as string
  my $pep = $tran->translate()->seq();

  # Get the exon cdna sequence.
  my $cdna = $trans->spliced_seq();

=head1 METHODS

=cut

package Bio::EnsEMBL::PredictionTranscript;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Feature;
use Bio::EnsEMBL::Transcript;
use Bio::EnsEMBL::Translation;

use Bio::EnsEMBL::Utils::Exception qw( deprecate throw warning );
use Bio::EnsEMBL::Utils::Argument qw( rearrange );

@ISA = qw(Bio::EnsEMBL::Transcript);


=head2 new

  Arg [-DISPLAY_LABEL]
    string - a displayable identifier for this prediction
  Arg [...]  : See Bio::EnsEMBL::Transcript superclass constructor
  Example    : $pt = Bio::EnsEMBL::PredictionTranscript->new
                  ( '-start'         =>  $seq_region_start,
                    '-end'           =>  $seq_region_end,
                    '-strand'        =>  $seq_region_strand,
                    '-adaptor'       =>  $self,
                    '-slice'         =>  $slice,
                    '-analysis'      =>  $analysis,
                    '-dbID'          =>  $prediction_transcript_id,
                    '-display_label' =>  $display_label);
  Description: Constructor. Creates a new Bio::EnsEMBL::PredictionTranscript
               object
  Returntype : Bio::EnsEMBL::PredictionTranscript
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);

  my ($display_label) = rearrange(['DISPLAY_LABEL'], @_);

  $self->{'display_label'} = $display_label;

  return $self;
}


=head2 coding_region_start

  Arg [1]    : none
  Example    : $coding_region_start = $pt->coding_region_start
  Description: Retrieves the start of the coding region of this transcript in
               slice coordinates.  For prediction transcripts this
               is always the start of the transcript (i.e. there is no UTR).
               By convention, the coding_region_start is always lower than
               the value returned by the coding_end method.
               The value returned by this function is NOT the biological
               coding start since on the reverse strand the biological coding
               start would be the higher genomic value.
  Returntype : int
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub coding_region_start {
  my $self = shift;
  return $self->start();
}


=head2 coding_region_end

  Arg [1]    : none
  Example    : $coding_region_end = $transcript->coding_region_end
  Description: Retrieves the start of the coding region of this prediction
               transcript. For prediction transcripts this is always the same
               as the end since no UTRs are stored.
               By convention, the coding_region_end is always higher than the
               value returned by the coding_region_start method.
               The value returned by this function is NOT the biological
               coding start since on the reverse strand the biological coding
               end would be the lower genomic value.
  Returntype : int
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub coding_region_end {
  my $self = shift;
  return $self->end();
}



=head2 get_all_translateable_Exons

  Arg [1]    : none
  Example    : $exons = $self->get_all_translateable_Exons
  Description: Retrieves the translateable portion of all exons in this
               transcript.  For prediction transcripts this means all exons
               since no UTRs are stored for them.
  Returntype : listref of Bio::EnsEMBL::PredictionExons
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub get_all_translateable_Exons {
  my $self = shift;
  return $self->get_all_Exons();
}


=head2 display_label

  Arg [1]    : string $newval (optional)
               The new value to set the display_label attribute to
  Example    : $display_label = $pt->display_label()
  Description: Getter/Setter for a displayable identifier for this
               prediction transcript.
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub display_label{
  my $self = shift;
  return $self->{'display_label'} = shift if(@_);
  return $self->{'display_label'};
}



=head2 stable_id

  Arg [1]    : none
  Example    : print $pt->stable_id();
  Description: Gets a 'stable' identifier for this prediction transcript.  Note
               that prediction transcripts do not have true *stable*
               identifiers (i.e. identifiers maintained between releases).
               This method chains to the display_label method and is intended
               to provide polymorphism with the Transcript class.
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub stable_id { return display_label(@_); }

sub get_all_DBEntries { return []; }

sub get_all_DBLinks { return []; }

sub add_DBEntry {}

sub external_db { return undef; }

sub external_status { return undef; }

sub external_name { return undef; }

sub is_known { return 0;}


=head2 translation

  Arg [1]    : none
  Example    : $translation = $pt->translation();
  Description: Retrieves a Bio::EnsEMBL::Translation object for this prediction
               transcript.  Note that this translation is generated on the fly
               and is not stored in the database.  The translation always
               spans the entire transcript (no UTRs; all CDS) and does not
               have an associated dbID, stable_id or adaptor.
  Returntype : int
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub translation {
  my $self = shift;

  #calculate translation on the fly
  my $strand = $self->strand();

  my $start_exon;
  my $end_exon;

  my @exons = @{$self->get_all_Exons()};

  return undef if(!@exons);

  $start_exon = $exons[0];
  $end_exon = $exons[-1];

  my $pta;

  if($self->adaptor()) {
    $pta = $self->adaptor()->db()->get_TranslationAdaptor();
  } else {
    #warning("PredictionTranscript has no adaptor, may not be able to obtain " .
           # "translation");
  }

  my $Xseq = $self->spliced_seq();
  my $start_phase = $start_exon->phase;
  if( $start_phase > 0 ) {
    $Xseq = "N"x$start_phase . $Xseq;
  }

  my $tmpSeq = new Bio::Seq( -id => $self->display_id,
			     -seq => $Xseq,
			     -moltype => "dna" );

  return Bio::EnsEMBL::Translation->new
    (-ADAPTOR    => $pta,
     -START_EXON => $start_exon,
     -END_EXON   => $end_exon,
     -SEQ_START  => 1,
     -SEQ_END    => $end_exon->length(),
     -SEQ        => $tmpSeq->translate()->seq());
}



=head2 translate

  Args      : none
  Function  : Give a peptide translation of all exons currently in
              the PT. Gives empty string when none is in.
  Returntype: a Bio::Seq as in transcript->translate()
  Exceptions: none
  Caller    : general
  Status     : Stable

=cut


sub translate {
  my ($self) = @_;

  my $dna = $self->translateable_seq();

  my $codon_table_id;
  if ( defined( $self->slice() ) ) {
      my $attrib;
      
      ($attrib) = @{ $self->slice()->get_all_Attributes('codon_table') };
      if ( defined($attrib) ) {
	  $codon_table_id = $attrib->value();
      }
  }
  $codon_table_id ||= 1; #default will be vertebrates

  if( CORE::length( $dna ) % 3 == 0 ) {
   # $dna =~ s/TAG$|TGA$|TAA$//i;
      my $codon_table =  Bio::Tools::CodonTable->new( -id => $codon_table_id );
      
      if ( $codon_table->is_ter_codon( substr( $dna, -3, 3 ) ) ) {
	  substr( $dna, -3, 3, '' );
      }
  }
  # the above line will remove the final stop codon from the mrna
  # sequence produced if it is present, this is so any peptide produced
  # won't have a terminal stop codon
  # if you want to have a terminal stop codon either comment this line out
  # or call translatable seq directly and produce a translation from it

  my $bioseq = new Bio::Seq(  -id => $self->display_id, -seq => $dna, -moltype => 'dna' );

  my $translation = $bioseq->translate(undef,undef,undef,$codon_table_id);

  return $translation;
}


=head2 cdna_coding_start

  Arg [1]    : none
  Example    : $relative_coding_start = $transcript->cdna_coding_start;
  Description: Retrieves the position of the coding start of this transcript
               in cdna coordinates (relative to the start of the 5prime end of
               the transcript, excluding introns, including utrs). This is
               always 1 for prediction transcripts because they have no UTRs.
  Returntype : int
  Exceptions : none
  Caller     : five_prime_utr, get_all_snps, general
  Status     : Stable

=cut

sub cdna_coding_start { return 1; }



=head2 cdna_coding_end

  Arg [1]    : none
  Example    : $relative_coding_start = $transcript->cdna_coding_start;
  Description: Retrieves the position of the coding end of this transcript
               in cdna coordinates (relative to the start of the 5prime end of
               the transcript, excluding introns, including utrs). This is
               always te length of the cdna for prediction transcripts because
               they have no UTRs.
  Returntype : int
  Exceptions : none
  Caller     : five_prime_utr, get_all_snps, general
  Status     : Stable

=cut

sub cdna_coding_end {
  my $self = shift;
  return length($self->spliced_seq);
}


=head2 transform

  Arg  1     : String $coordinate_system_name
  Arg [2]    : String $coordinate_system_version
  Example    : $ptrans = $ptrans->transform('chromosome', 'NCBI33');
               $ptrans = $ptrans->transform('clone');
  Description: Moves this PredictionTranscript to the given coordinate system.
               If this Transcript has Exons attached, they move as well.
               A new Transcript is returned or undefined if this PT is not
               defined in the new coordinate system.
  Returntype : Bio::EnsEMBL::PredictionTranscript
  Exceptions : wrong parameters
  Caller     : general
  Status     : Stable

=cut

sub transform {
  my $self = shift;

  # catch for old style transform calls
  if( ref $_[0] && $_[0]->isa( "Bio::EnsEMBL::Slice" )) {
    throw("transform needs coordinate systems details now," .
          "please use transfer");
  }

  my $new_transcript = Bio::EnsEMBL::Feature::transform($self, @_ );
  return undef unless $new_transcript;

  #go through the _trans_exon_array so as not to prompt lazy-loading
  if(exists($self->{'_trans_exon_array'})) {
    my @new_exons;
    foreach my $old_exon ( @{$self->{'_trans_exon_array'}} ) {
      my $new_exon = $old_exon->transform(@_);
      push(@new_exons, $new_exon);
    }
    $new_transcript->{'_trans_exon_array'} = \@new_exons;
  }

  return $new_transcript;
}



=head2 transfer

  Arg  1     : Bio::EnsEMBL::Slice $destination_slice
  Example    : $ptrans = $ptrans->transfer($slice);
  Description: Moves this PredictionTranscript to the given slice.
               If this Transcripts has Exons attached, they move as well.
               If this transcript cannot be moved then undef is returned
               instead.
  Returntype : Bio::EnsEMBL::PredictionTranscript
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub transfer {
  my $self = shift;

  my $new_transcript = $self->SUPER::transfer( @_ );
  return undef unless $new_transcript;

  if( exists $self->{'_trans_exon_array'} ) {
    my @new_exons;
    for my $old_exon ( @{$self->{'_trans_exon_array'}} ) {
      my $new_exon = $old_exon->transfer( @_ );
      push( @new_exons, $new_exon );
    }

    $new_transcript->{'_trans_exon_array'} = \@new_exons;
  }

  return $new_transcript;
}

=head2 get_all_Exons

  Arg [1]    : none
  Example    : my @exons = @{$transcript->get_all_Exons()};
  Description: Returns an listref of the exons in this transcipr in order.
               i.e. the first exon in the listref is the 5prime most exon in 
               the transcript.
  Returntype : a list reference to Bio::EnsEMBL::Exon objects
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub get_all_Exons {
   my ($self) = @_;
   if( ! defined $self->{'_trans_exon_array'} && defined $self->adaptor() ) {
     $self->{'_trans_exon_array'} = $self->adaptor()->db()->
       get_PredictionExonAdaptor()->fetch_all_by_PredictionTranscript( $self );
   }
   return $self->{'_trans_exon_array'};
}

=head2 display_id

  Arg [1]    : none
  Example    : print $rf->display_id();
  Description: This method returns a string that is considered to be
               the 'display' identifier. For prediction transcripts this is
               (depending on availability and in this order) the stable Id, the
               dbID or an empty string.
  Returntype : string
  Exceptions : none
  Caller     : web drawing code
  Status     : Stable

=cut

sub display_id {
  my $self = shift;
  return $self->stable_id || $self->dbID || '';
}

=head2 get_all_Attributes

  Arg [1]    : none
  Example    :
  Description: DOES NOTHING, Returns empty listref. Provided here to prevent
               Transcript attributes being returned for PredictionTranscripts.
  Returntype : EMPTY listref Bio::EnsEMBL::Attribute
  Exceptions : none
  Caller     : general
  Status     : At risk

=cut

sub get_all_Attributes {
  my $self = shift;

  return [];
}



=head2 get_exon_count

  Description: DEPRECATED - use get_all_Exons instead

=cut

sub get_exon_count {
   my $self = shift;
   deprecate('Use scalar(@{$transcript->get_all_Exon()s}) instead');
   return scalar( @{$self->get_all_Exons} );
}


=head2 set_exon_count

  Description: DEPRECATED - this method does nothing now

=cut

sub set_exon_count {
  deprecate('This method no longer does anything.');
}



=head2 get_cdna

  Description : DEPRECATED - use spliced_seq() or translateable_seq instead

=cut

sub get_cdna {
  my $self = shift;
  deprecate('use spliced_seq instead');
  return $self->spliced_seq();
}

1;
