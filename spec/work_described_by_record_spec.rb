require 'spec_helper'
require 'linkeddata'

describe 'the work described by the MARC record' do

  # Stanford:
  # MARC fields that identify “a work described by the record”:
  # 130
  # 100|110|111 and 240
  # 100|110|111 and 245
  # 245 (‡a) if no 1xx

  # marc2bibframe xquery converter
  # Each Bib Record creates a Work
  # PLUS
  # 130|240  # uniform title
  # 880 for 130|240  vernacular uniform title

  let(:marc_ldr_001_008) {
    '<record xmlns="http://www.loc.gov/MARC21/slim">
      <leader>01855cemaa22003131a 4500</leader>
      <controlfield tag="001">aRECORD_ID</controlfield>
      <controlfield tag="008">760219s1925    en            000 0 eng  </controlfield>'
  }
  let(:work_squery) {
    SPARQL.parse("PREFIX bf: <http://bibframe.org/vocab/>
                  SELECT DISTINCT ?work
                  WHERE {
                    ?work a bf:Work .
                  }") }
  # TODO:  rework title query for workTitle (?)
  # TODO:  title shouldn't have certain subfields (e.g. ‡=, ‡?)
  let(:work_title_sparql) {"PREFIX bf: <http://bibframe.org/vocab/>
                            SELECT DISTINCT ?work
                            WHERE {
                              ?work a bf:Work .
                              ?work bf:authorizedAccessPoint ?aap .
                              FILTER regex(?aap, 'TITLE_REGEX', 'i')
                            }" }

  context "130" do
    let(:beowulf_work_title_squery) { SPARQL.parse(work_title_sparql.sub('TITLE_REGEX', 'Beowulf'))}

    it '130 ‡a only has single work' do
      rec_id = '130a_only'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="0" ind2=" " tag="130">
          <subfield code="a">Beowulf.</subfield>
        </datafield>
        <datafield ind1="0" ind2="0" tag="245">
          <subfield code="a">Beowulf</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      expect(g.query(beowulf_work_title_squery).size).to eq 1
    end
    it '130 ‡a only has single work with title from 130' do
      rec_id = '130a_title'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="0" ind2=" " tag="130">
          <subfield code="a">Beowulf.</subfield>
        </datafield>
        <datafield ind1="0" ind2="0" tag="245">
          <subfield code="a">ignore me</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      expect(g.query(beowulf_work_title_squery).size).to eq 1
      work_title_squery = SPARQL.parse(work_title_sparql.sub('TITLE_REGEX', 'ignore'))
      expect(g.query(work_title_squery).size).to eq 0
    end
    it '130 ‡a, ‡= has single work' do
      rec_id = '130a_equal'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="0" ind2=" " tag="130">
          <subfield code="a">Beowulf.</subfield>
          <subfield code="=">^A944917</subfield>
        </datafield>
        <datafield ind1="0" ind2="0" tag="245">
          <subfield code="a">ignore me</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      expect(g.query(beowulf_work_title_squery).size).to eq 1
    end
    it '130 ‡a, ‡n, ‡? has single work' do
      rec_id = '130an_question_mark'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="0" ind2=" " tag="130">
          <subfield code="a">Annale.</subfield>
          <subfield code="n">Reeks B (University of Stellenbosch : 1979)</subfield>
          <subfield code="?">UNAUTHORIZED</subfield>
        </datafield>
        <datafield ind1="0" ind2="0" tag="245">
          <subfield code="a">Annale.</subfield>
          <subfield code="n">Reeks B /</subfield>
          <subfield code="c">Universiteit van Stellebosch.</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      work_title_squery = SPARQL.parse(work_title_sparql.sub('TITLE_REGEX', 'Annale'))
      expect(g.query(work_title_squery).size).to eq 1
    end
    it '130 non-filing characters (ind1)' do
      fail 'test to be implemented'
    end
  end # context 130

  context "100|110|111 and 240" do
    it '100 ‡a, ‡? and 240 ‡a, ‡? has single work' do
      rec_id = '100a_240a_question_marks'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="1" ind2=" " tag="100">
          <subfield code="a">Davis, Miles.</subfield>
          <subfield code="?">UNAUTHORIZED</subfield>
        </datafield>
        <datafield ind1="1" ind2="0" tag="240">
          <subfield code="a">Birth of the cool</subfield>
          <subfield code="?">UNAUTHORIZED</subfield>
        </datafield>
        <datafield ind1="1" ind2="0" tag="245">
          <subfield code="a">ignored</subfield>
          <subfield code="c">Miles Davis.</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      title_squery = SPARQL.parse(" PREFIX bf: <http://bibframe.org/vocab/>
                                    SELECT DISTINCT ?work
                                    WHERE {
                                      ?work a bf:Work .
                                      ?work bf:authorizedAccessPoint ?aap .
                                      FILTER regex(?aap, 'Davis, Miles', 'i')
                                      FILTER regex(?aap, 'Birth of the cool', 'i')
                                    }")
      expect(g.query(title_squery).size).to eq 1
      work_title_squery = SPARQL.parse(work_title_sparql.sub('TITLE_REGEX', 'ignore'))
      expect(g.query(work_title_squery).size).to eq 0
    end
    it '110 ‡a, ‡b, ‡= and 240 ‡a has single work' do
      rec_id = '110ab_240a_equal'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="1" ind2=" " tag="110">
          <subfield code="a">South Africa.</subfield>
          <subfield code="b">Department of Education</subfield>
          <subfield code="=">^A1298224</subfield>
        </datafield>
        <datafield ind1="1" ind2="0" tag="240">
          <subfield code="a">Annual report (Online)</subfield>
        </datafield>
        <datafield ind1="1" ind2="0" tag="245">
          <subfield code="a">ignore</subfield>
          <subfield code="h">[electronic resource] /</subfield>
          <subfield code="c">Department of Education.</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      title_squery = SPARQL.parse(" PREFIX bf: <http://bibframe.org/vocab/>
                                    SELECT DISTINCT ?work
                                    WHERE {
                                      ?work a bf:Work .
                                      ?work bf:authorizedAccessPoint ?aap .
                                      FILTER regex(?aap, 'South Africa', 'i')
                                      FILTER regex(?aap, 'Department of Education', 'i')
                                      FILTER regex(?aap, 'Annual report', 'i')
                                    }")
      expect(g.query(title_squery).size).to eq 1
      work_title_squery = SPARQL.parse(work_title_sparql.sub('TITLE_REGEX', 'ignore'))
      expect(g.query(work_title_squery).size).to eq 0
      work_title_squery = SPARQL.parse(work_title_sparql.sub('TITLE_REGEX', 'electronic resource'))
      expect(g.query(work_title_squery).size).to eq 0
    end
    it '111 ‡a, ‡? and 240 ‡a has single work' do
      rec_id = '111a_240a'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="2" ind2=" " tag="111">
          <subfield code="a">International Workshop on Faces.</subfield>
          <subfield code="?">UNAUTHORIZED</subfield>
        </datafield>
        <datafield ind1="1" ind2="0" tag="240">
          <subfield code="a">Proceedings (Online)</subfield>
        </datafield>
        <datafield ind1="1" ind2="0" tag="245">
          <subfield code="a">ignore a</subfield>
          <subfield code="h">[ignore h] /</subfield>
          <subfield code="c">ignore c</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      title_squery = SPARQL.parse(" PREFIX bf: <http://bibframe.org/vocab/>
                                    SELECT DISTINCT ?work
                                    WHERE {
                                      ?work a bf:Work .
                                      ?work bf:authorizedAccessPoint ?aap .
                                      FILTER regex(?aap, 'International Workshop on Faces', 'i')
                                      FILTER regex(?aap, 'Proceedings', 'i')
                                    }")
      expect(g.query(title_squery).size).to eq 1
      work_title_squery = SPARQL.parse(work_title_sparql.sub('TITLE_REGEX', 'ignore'))
      expect(g.query(work_title_squery).size).to eq 0
    end
    # http://www.loc.gov/marc/bibliographic/bd240.html
    it 'ind1 = 0  (not printed or displayed)' do
      fail 'test to be implemented'
    end
    it '240 non-filing chars (2nd indicator' do
      fail 'test to be implemented'
    end
  end # context 1xx and 240

  # 240 and no 1xx shouldn't happen

  context "100|110|111 and 245" do
    it '100 ‡a, ‡d, ‡e, ‡= and 245 ‡a, ‡b, ‡c' do
      rec_id = '100ade_245abc'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="1" ind2=" " tag="100">
          <subfield code="a">Lin, Hsiang-ju,</subfield>
          <subfield code="d">1931-</subfield>
          <subfield code="e">author.</subfield>
          <subfield code="=">^A1797002</subfield>
        </datafield>
        <datafield ind1="1" ind2="0" tag="245">
          <subfield code="a">Slippery noodles :</subfield>
          <subfield code="b">a culinary history of China /</subfield>
          <subfield code="c">Hsiang Ju Lin.</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      title_squery = SPARQL.parse(" PREFIX bf: <http://bibframe.org/vocab/>
                                    SELECT DISTINCT ?work
                                    WHERE {
                                      ?work a bf:Work .
                                      ?work bf:authorizedAccessPoint ?aap .
                                      FILTER regex(?aap, 'Lin, Hsiang-ju', 'i')
                                      FILTER regex(?aap, '1931', 'i')
                                      FILTER regex(?aap, 'Slippery noodles', 'i')
                                      FILTER regex(?aap, 'a culinary history of China', 'i')
                                    }")
      expect(g.query(title_squery).size).to eq 1
      # TODO:  should we ignore 245c (b/c we have 100?)
      #work_title_squery = SPARQL.parse(work_title_sparql.sub('TITLE_REGEX', 'Hsiang Ju Lin'))
      #expect(g.query(work_title_squery).size).to eq 0
    end
    it '110 ‡a, ‡b, ‡= and 245 ‡a, ‡f' do
      rec_id = '110ab_245af'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="2" ind2=" " tag="110">
          <subfield code="a">Stanford University.</subfield>
          <subfield code="b">Women\'s Community Center.</subfield>
          <subfield code="=">^A104006</subfield>
        </datafield>
        <datafield ind1="1" ind2="0" tag="245">
          <subfield code="a">Stanford University, Women\'s Community Center, records,</subfield>
          <subfield code="f">2007-2014.</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      title_squery = SPARQL.parse(" PREFIX bf: <http://bibframe.org/vocab/>
                                    SELECT DISTINCT ?work
                                    WHERE {
                                      ?work a bf:Work .
                                      ?work bf:authorizedAccessPoint ?aap .
                                      FILTER regex(?aap, 'Stanford University', 'i')
                                      FILTER regex(?aap, 'Women\\'s Community Center', 'i')
                                      FILTER regex(?aap, 'records', 'i')
                                    }")
      expect(g.query(title_squery).size).to eq 1
    end
    it '111 ‡a ‡n ‡d ‡c ‡= and 245 ‡a ‡b ‡c' do
      rec_id = '111andc_245abc'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="2" ind2=" " tag="111">
          <subfield code="a">International Jean Sibelius Conference</subfield>
          <subfield code="n">(3rd :</subfield>
          <subfield code="d">2000 :</subfield>
          <subfield code="c">Helsinki, Finland)</subfield>
          <subfield code="=">^A1791312</subfield>
        </datafield>
        <datafield ind1="1" ind2="0" tag="245">
          <subfield code="a">Sibelius forum II :</subfield>
          <subfield code="b">proceedings from the third International Jean Sibelius Conference, Helsinki, December 7-10, 2000 /</subfield>
          <subfield code="c">edited by Matti Huttunen, Kari Kilpeläinen and Veijo Murtomäki.</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      title_squery = SPARQL.parse(" PREFIX bf: <http://bibframe.org/vocab/>
                                    SELECT DISTINCT ?work
                                    WHERE {
                                      ?work a bf:Work .
                                      ?work bf:authorizedAccessPoint ?aap .
                                      FILTER regex(?aap, 'International Jean Sibelius Conference', 'i')
                                      FILTER regex(?aap, '2000', 'i')
                                      FILTER regex(?aap, 'Helsinki, Finland', 'i')
                                      FILTER regex(?aap, 'Sibelius forum II', 'i')
                                      FILTER regex(?aap, 'proceedings from the third', 'i')
                                    }")
      expect(g.query(title_squery).size).to eq 1
    end
    it '245 non-filing chars (ind2)' do
      rec_id = '100_245_non_filing'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="1" ind2=" " tag="100">
          <subfield code="a">Walker, Alice,</subfield>
          <subfield code="d">1944-</subfield>
          <subfield code="=">^A128228</subfield>
        </datafield>
        <datafield ind1="1" ind2="4" tag="245">
          <subfield code="a">The color purple :</subfield>
          <subfield code="b">a novel /</subfield>
          <subfield code="c">by Alice Walker.</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      title_squery = SPARQL.parse(" PREFIX bf: <http://bibframe.org/vocab/>
                                    SELECT DISTINCT ?work
                                    WHERE {
                                      ?work a bf:Work .
                                      ?work bf:authorizedAccessPoint ?aap .
                                      FILTER regex(?aap, 'Walker, Alice', 'i')
                                      FILTER regex(?aap, 'The color purple', 'i')
                                      FILTER regex(?aap, 'a novel', 'i')
                                    }")
      expect(g.query(title_squery).size).to eq 1
      skip 'non-filing chars in title bf:title property on bf:Work'
    end
  end # context 1xx and 245

  context "245 no 1xx" do
    it '245 ‡a ‡b ‡c' do
      rec_id = '245only'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="0" ind2="0" tag="245">
          <subfield code="a">Primary colors :</subfield>
          <subfield code="b">a novel of politics /</subfield>
          <subfield code="c">Anonymous.</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      title_squery = SPARQL.parse(" PREFIX bf: <http://bibframe.org/vocab/>
                                    SELECT DISTINCT ?work
                                    WHERE {
                                      ?work a bf:Work .
                                      ?work bf:authorizedAccessPoint ?aap .
                                      FILTER regex(?aap, 'Primary colors', 'i')
                                      FILTER regex(?aap, 'a novel of politics', 'i')
                                      FILTER regex(?aap, 'Anonymous', 'i')
                                    }")
      expect(g.query(title_squery).size).to eq 1
    end
    it '245 non-filing chars (ind2)' do
      rec_id = '245only_non_filing'
      marcxml_str = marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="0" ind2="2" tag="245">
          <subfield code="a">A Memoir of Mary Ann /</subfield>
          <subfield code="c">by the Dominican nuns of Our Lady of Perpetual Help Home, Atlanta, Georgia ; introduction by Flannery O\'Connor.</subfield>
        </datafield>
      </record>'
      g = self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id)
      expect(g.query(work_squery).size).to eq 1
      title_squery = SPARQL.parse(" PREFIX bf: <http://bibframe.org/vocab/>
                                    SELECT DISTINCT ?work
                                    WHERE {
                                      ?work a bf:Work .
                                      ?work bf:authorizedAccessPoint ?aap .
                                      FILTER regex(?aap, 'A Memoir of Mary Ann', 'i')
                                      FILTER regex(?aap, 'by the Dominican nuns of Our Lady of Perpetual Help Home', 'i')
                                    }")
      expect(g.query(title_squery).size).to eq 1
      skip 'non-filing chars in title bf:title property on bf:Work'
    end

  end # context 245 no 1xx


end
