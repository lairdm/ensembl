-- Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

# patch_74_75_g.sql
#
# Title: New tables to store expression data
#
# Description: We can now store expression data on gene, transcript and exon level
# The tissue describes the conditions where the data was seen


CREATE TABLE gene_expression (
  gene_expression_id          INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  gene_id                     INT(10) UNSIGNED NOT NULL,
  tissue_id                   INT(10) UNSIGNED NOT NULL,
  value                       TEXT NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  value_type                  ENUM('count', 'RPKM') NOT NULL,

  PRIMARY KEY (gene_expression_id),
  UNIQUE KEY gene_expression_idx(gene_id, tissue_id, analysis_id, value_type)
) ENGINE=MyISAM;

CREATE TABLE transcript_expression (
  transcript_expression_id          INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  transcript_id                     INT(10) UNSIGNED NOT NULL,
  tissue_id                   INT(10) UNSIGNED NOT NULL,
  value                       TEXT NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  value_type                  ENUM('count', 'RPKM') NOT NULL,

  PRIMARY KEY (transcript_expression_id),
  UNIQUE KEY transcript_expression_idx(transcript_id, tissue_id, analysis_id, value_type)
) ENGINE=MyISAM;

CREATE TABLE exon_expression (
  exon_expression_id          INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  exon_id                     INT(10) UNSIGNED NOT NULL,
  tissue_id                   INT(10) UNSIGNED NOT NULL,
  value                       TEXT NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  value_type                  ENUM('count', 'RPKM') NOT NULL,

  PRIMARY KEY (exon_expression_id),
  UNIQUE KEY exon_expression_idx(exon_id, tissue_id, analysis_id, value_type)
) ENGINE=MyISAM;

CREATE TABLE tissue (
  tissue_id                   INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  ontology                    VARCHAR(64) NOT NULL,
  name                        VARCHAR(255),
  description                 TEXT,

  PRIMARY KEY (tissue_id),
  UNIQUE KEY name_idx (name)
) ENGINE=MyISAM;

# Patch identifier
INSERT INTO meta (species_id, meta_key, meta_value)
  VALUES (NULL, 'patch', 'patch_74_75_g.sql|expression_data');
