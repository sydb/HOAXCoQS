<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:hoaxcoqs="https://github.com/sydb/HOAXCoQS/"
  xpath-default-namespace="http://www.w3.org/1999/XSL/Transform"
  version="3.0">
  <!--
    HOAXCoQS: Highly Opinionated Approximative XSLT Code Quality Score
    Idea by Gerrit Imsieke, posted to xml.com slack channel 2020-05-08.
    Coded into XSLT by Syd Bauman. I started 05-08, but finished 05-09.
    Copyleft 2020 by Syd Bauman and Gerrit Imsieke.
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
    2020-05-10 ~08:00 UTC by Gerrit Imsieke: Process all XSL files in the 
                      directory as specified by the $dir param.
                      Also, output the score as an xsl:message instead 
                      of text.
    2020-05-10 ~10:00 UTC by Gerrit Imsieke: JSON output, accept 
                      space-separated list of directories in dir
    2020-05-10 ~16:00 UTC by Gerrit Imsieke: Use 'good' and 'bad' modes
                      instead of 'good' and 'bad' keys in order to support 
                      weights when counting occurrences. (Version 1.2)
  -->
  <!--
    Version 1.2: Weight support. The weights (default: 1) can be 
      customized by importing the stylesheet, as demonstrated
      in xslt1fan.xsl.
      The program’s HOAXCoQS (including xslt1fan.xsl) is now 69.23.
    Version 1.1: Program can alternatively process directories. 
      The program’s HOAXCoQS is now 47.92.
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

  <xsl:mode name="bad" on-no-match="shallow-skip"/>
  <xsl:mode name="good" on-no-match="shallow-skip"/>
  
  <xsl:template match="value-of | for-each" mode="bad" as="xs:double+">
    <xsl:sequence select="1"/>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="for-each-group | next-match | apply-templates | sequence | assert | @as | @tunnel" 
    mode="good" as="xs:double+">
    <xsl:sequence select="1"/>
    <xsl:next-match/>
  </xsl:template>


  <xsl:param name="dir" as="xs:string?" select="()">
    <!-- A file URI for a directory that is recursively scanned.
         If the $dir param contains whitespace, each token will 
         be treated as a distinct directory to process.
         All files whose names end in '.xsl' or '.xslt' are processed.
         If the files are not well-formed, they won’t be processed.
         If $dir, or rather, the tokens, are relative paths, they
         are resolved against the base URI of this stylesheet.
         If this parameter is given, a potential source document is 
         ignored, and Saxon needs to be invoked with the -it switch 
         (no initial template name though).
    -->
  </xsl:param>

  <xsl:output method="json"/>
  
  <xsl:template match="/" as="map(xs:string, item())">
    <xsl:variable name="total" select="count( //xsl:* )" as="xs:integer"/>
    <xsl:variable name="weighted" as="map(xs:string, xs:anyAtomicType)"
      select="hoaxcoqs:apply-weights(.)"/><!-- a map with a 'good' 
        and a 'bad' key, and (possibly weighted) counts as values -->
    <xsl:variable name="counts" as="map(xs:string, item())?"
      select="hoaxcoqs:counts($total, $weighted?good, $weighted?bad, document-uri(.))"/>
    <xsl:if test="empty($dir)">
      <xsl:call-template name="hoaxcoqs:message"> 
        <xsl:with-param name="counts" select="$counts"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:sequence select="$counts"/>
  </xsl:template>

  <xsl:template name="hoaxcoqs:message">
    <xsl:param name="counts" as="map(xs:string, item())"/>
    <xsl:message select="'The HOAXCoQS score of', 
      string-join(array:flatten($counts?uri), ' '), 'is',
      format-number( hoaxcoqs:score($counts?total, $counts?good, $counts?bad), '###.99')"/>
  </xsl:template>
  
  <xsl:template name="xsl:initial-template">
    <xsl:variable name="individual-results" as="map(xs:string, item())*">
      <xsl:for-each-group group-by="base-uri()" 
        select="tokenize($dir) ! collection(. || '?recurse=yes;select=*.(xsl|xslt);on-error=warning')">
        <xsl:apply-templates select="."/>  
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:variable name="counts" as="map(xs:string, item())"
        select="hoaxcoqs:counts(
                  sum($individual-results ! ?total),
                  sum($individual-results ! ?good),
                  sum($individual-results ! ?bad),
                  tokenize($dir) ! resolve-uri(.)
                )"/>
    <xsl:call-template name="hoaxcoqs:message">
      <xsl:with-param name="counts" select="$counts"/> 
    </xsl:call-template>
    <xsl:sequence select="$counts"/>
  </xsl:template>

  <xsl:function name="hoaxcoqs:score" as="xs:double">
    <xsl:param name="total" as="xs:integer"/>
    <xsl:param name="good" as="xs:double"/>
    <xsl:param name="bad" as="xs:double"/>
    <xsl:sequence select="100 * ($good - $bad) div $total"/>
  </xsl:function>

  <xsl:function name="hoaxcoqs:counts" as="map(xs:string, item())">
    <xsl:param name="total" as="xs:integer"/>
    <xsl:param name="good" as="xs:double"/>
    <xsl:param name="bad" as="xs:double"/>
    <xsl:param name="uris" as="xs:anyURI+"/>
    <xsl:map>
      <xsl:map-entry key="'total'" select="$total"/>
      <xsl:map-entry key="'good'" select="$good"/>
      <xsl:map-entry key="'bad'" select="$bad"/>
      <xsl:map-entry key="'uri'" select="array { $uris }"/>
      <xsl:map-entry key="'score'" select="hoaxcoqs:score($total, $good, $bad)"/>
    </xsl:map>
  </xsl:function>

  <xsl:function name="hoaxcoqs:apply-weights" as="map(xs:string, xs:anyAtomicType)">
    <xsl:param name="stylesheet" as="document-node(element(*))?"/>
    <xsl:variable name="goods" as="xs:double*">
      <xsl:apply-templates select="$stylesheet" mode="good"/>
    </xsl:variable>
    <xsl:variable name="bads" as="xs:double*">
      <xsl:apply-templates select="$stylesheet" mode="bad"/>
    </xsl:variable>
    <xsl:sequence select="map { 
                                'good': sum($goods),
                                'bad' : sum($bads)
                              }"/>
  </xsl:function>
  

</xsl:stylesheet>