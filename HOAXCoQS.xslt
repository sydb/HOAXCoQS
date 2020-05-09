<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xpath-default-namespace="http://www.w3.org/1999/XSL/Transform"
  version="3.0">
  <!--
    HOAXCoQS: Highly Opinionated Approximative XSLT Code Quality Score
    Idea by Gerrit Imsieke, posted to xml.com slack channel 2020-05-08.
    Coded into XSLT by Syd Bauman. I started 05-08, but finished 05-09.
    Copyleft 2020 by Syd Bauman.
  -->
  <!--
    Revision history
    ======== =======
    2020-05-08 ~23:50 by Syd Bauman: started
    2020-05-09 ~00:05 by Syd Bauman: first draft code complete
    2020-05-09 ~00:20 by Syd Bauman: comments added, posted to slack
    2020-05-09 ~00:25 by Syd Bauman: bug fix: count only XSL elements for
                      the denominator. Also factor out common divide by
                      $total in the calculation.
    2020-05-09 ~00:30 by Syd Bauman: Add this revision hx.
  -->
  <!--
    Version 1: algorithm as (I think) Gerrit used on his spreadsheet, but
    works only on a single XSLT file. BTW, the HOAXCoQS for this program
    is 11.76.
    
    Future plans:
    * improve algorithm, including weighting of constructs and using
      attributes (perhaps weighted) in the denominator
    * use weighted counts of # of “words” inside comments or <xd:doc>
      as part of good
    * follow <import> and <include>, so those stylesheets are counted,
      too
    * wait until 2021-04-01 and then post it and have a ball!
    
    Things I don’t currently plan to implement, but might be a good idea:
    * Count times that atomics are compared using ‘=’, not “eq” (etc.)
    * Examine whitespace and count as bad anything not indented properly
  -->
  <xsl:key name="good" match="for-each-group" use="true()"/>
  <xsl:key name="good" match="next-match" use="true()"/>
  <xsl:key name="good" match="apply-templates" use="true()"/>
  <xsl:key name="good" match="sequence" use="true()"/>
  <xsl:key name="good" match="@tunnel" use="true()"/>
  <xsl:key name="good" match="@as" use="true()"/>
  
  <xsl:key name="bad" match="for-each" use="true()"/>
  <xsl:key name="bad" match="value-of" use="true()"/>

  <xsl:output method="text"/>
  
  <xsl:template match="/">
    <xsl:variable name="total" select="count( //xsl:* )"/>
    <xsl:variable name="good" select="count( key('good', true() ) )"/>
    <xsl:variable name="bad" select="count( key('bad', true() ) )"/>
    <xsl:sequence select="'The HOAXCoQS score of '||document-uri(/)||' is '"/>
    <xsl:sequence select="100 * ( ( $good - $bad ) div $total )"/>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>
  
</xsl:stylesheet>