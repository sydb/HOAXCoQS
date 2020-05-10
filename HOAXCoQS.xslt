<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
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
  -->
  <!--
    Version 1.1: Program can alternatively process directories. 
      The program’s HOAXCoQS is now 47.37.
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
  <xsl:key name="good" match="assert" use="true()"/>
  <xsl:key name="good" match="@tunnel" use="true()"/>
  <xsl:key name="good" match="@as" use="true()"/>
  
  <xsl:key name="bad" match="for-each" use="true()"/>
  <xsl:key name="bad" match="value-of" use="true()"/>

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
  
  <xsl:template match="/" as="map(xs:string, xs:anyAtomicType)">
    <!-- GI: I’d like to use "map(xs:string, xs:integer)?", but I cannot specify
      a more detailed value type on xsl:map below -->
    <xsl:variable name="total" select="count( //xsl:* )" as="xs:integer"/>
    <xsl:variable name="good" select="count( key('good', true() ) )" as="xs:integer"/>
    <xsl:variable name="bad" select="count( key('bad', true() ) )" as="xs:integer"/>
    <xsl:variable name="counts" as="map(xs:string, xs:anyAtomicType)?"
      select="hoaxcoqs:counts($total, $good, $bad, document-uri(.))"/>
    <xsl:if test="empty($dir)">
      <xsl:call-template name="hoaxcoqs:message"> 
        <xsl:with-param name="counts" select="$counts"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:sequence select="$counts"/>
  </xsl:template>

  <xsl:template name="hoaxcoqs:message">
    <xsl:param name="counts" as="map(xs:string, xs:anyAtomicType)"/>
    <xsl:message select="'The HOAXCoQS score of', (resolve-uri($dir), document-uri(/))[1], 'is',
      format-number( hoaxcoqs:score($counts?total, $counts?good, $counts?bad), '###.99')"/>
  </xsl:template>
  
  <xsl:template name="xsl:initial-template">
    <xsl:variable name="individual-results" as="map(xs:string, xs:anyAtomicType)*">
      <xsl:for-each-group group-by="base-uri()" 
        select="tokenize($dir) ! collection(. || '?recurse=yes;select=*.(xsl|xslt);on-error=warning')">
        <xsl:apply-templates select="."/>  
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:variable name="total" as="xs:integer" select="sum($individual-results ! ?total)"/>
    <xsl:variable name="good" as="xs:integer" select="sum($individual-results ! ?good)"/>
    <xsl:variable name="bad" as="xs:integer" select="sum($individual-results ! ?bad)"/>
    <xsl:variable name="counts" as="map(xs:string, xs:anyAtomicType)">
      <xsl:map>
        <xsl:map-entry key="'total'" select="$total"/>
        <xsl:map-entry key="'good'" select="$good"/>
        <xsl:map-entry key="'bad'" select="$bad"/>
        <xsl:map-entry key="'uri'" select="(resolve-uri($dir))"/>
        <xsl:map-entry key="'score'" select="hoaxcoqs:score($total, $good, $bad)"/>
      </xsl:map>
    </xsl:variable>
    <xsl:call-template name="hoaxcoqs:message">
      <xsl:with-param name="counts" select="$counts" as="map(xs:string, xs:anyAtomicType)"/>
    </xsl:call-template>
    <xsl:sequence select="$counts"/>
  </xsl:template>

  <xsl:function name="hoaxcoqs:score" as="xs:double">
    <xsl:param name="total" as="xs:integer"/>
    <xsl:param name="good" as="xs:integer"/>
    <xsl:param name="bad" as="xs:integer"/>
    <xsl:sequence select="100 * ($good - $bad) div $total"/>
  </xsl:function>

  <xsl:function name="hoaxcoqs:counts" as="map(xs:string, xs:anyAtomicType)">
    <xsl:param name="total" as="xs:integer"/>
    <xsl:param name="good" as="xs:integer"/>
    <xsl:param name="bad" as="xs:integer"/>
    <xsl:param name="uris" as="xs:anyURI+"/>
    <xsl:map>
      <xsl:map-entry key="'total'" select="$total"/>
      <xsl:map-entry key="'good'" select="$good"/>
      <xsl:map-entry key="'bad'" select="$bad"/>
      <xsl:map-entry key="'uri'" select="[ $uris ]"/>
      <xsl:map-entry key="'score'" select="hoaxcoqs:score($total, $good, $bad)"/>
    </xsl:map>
  </xsl:function>


</xsl:stylesheet>