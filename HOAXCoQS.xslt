<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
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
    2020-05-10 ~08:00 UTC by Gerrit Imsieke: Process all XSL files in the 
                      directory as specified by the $dir param.
                      Also, output the score as an xsl:message instead 
                      of text.
  -->
  <!--
    Version 1: algorithm as (I think) Gerrit used on his spreadsheet, but
    works only on a single XSLT file. BTW, the HOAXCoQS for this program
    is 25.64.
    
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

  <xsl:param name="dir" as="xs:string?" select="()">
    <!-- A file URI for a directory that is recursively scanned. 
         All files whose names end in '.xsl' or '.xslt' are processed.
         If the files are not well-formed, they won’t be analyzed.
         If $dir is a relative path, it is resolved against the base 
         URI of this stylesheet.
         If this parameter is given, a potential source document is 
         ignored, and saxon needs to be invoked with the -it switch 
         (no initial template name though).
    -->
  </xsl:param>

  <xsl:output method="text"/>
  
  <xsl:template match="/" as="map(xs:string, xs:anyAtomicType)?">
    <!-- GI: I’d like to use "map(xs:string, xs:integer)?", but I cannot specify
      a more detailed value type on xsl:map below -->
    <xsl:variable name="total" select="count( //xsl:* )" as="xs:integer"/>
    <xsl:variable name="good" select="count( key('good', true() ) )" as="xs:integer"/>
    <xsl:variable name="bad" select="count( key('bad', true() ) )" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="$dir">
        <!-- don’t output anything yet, just return this document’s counts -->
        <xsl:map>
          <xsl:map-entry key="'total'" select="$total"/>
          <xsl:map-entry key="'good'" select="$good"/>
          <xsl:map-entry key="'bad'" select="$bad"/>
          <!-- we don’t use the URIs yet -->
          <xsl:map-entry key="'uri'" select="document-uri(.)"/>
        </xsl:map>
      </xsl:when>
      <xsl:otherwise>
        <!-- output the score for a single source document -->
        <xsl:call-template name="text-output">
          <xsl:with-param name="total" select="$total"/>
          <!-- omitting @as attributes here since we don’t want to artificially 
               boost this stylesheet’s score -->
          <xsl:with-param name="good" select="$good"/>
          <xsl:with-param name="bad" select="$bad"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="text-output">
    <xsl:param name="total" as="xs:integer"/>
    <xsl:param name="good" as="xs:integer"/>
    <xsl:param name="bad" as="xs:integer"/>
    <xsl:message select="'The HOAXCoQS score of', ($dir, document-uri(/))[1], 'is',
      format-number( 100 * ( ( $good - $bad ) div $total ), '###.99')"/>
  </xsl:template>
  
  <xsl:template name="xsl:initial-template">
    <xsl:variable name="results" as="map(xs:string, xs:anyAtomicType)*">
      <xsl:apply-templates 
        select="collection($dir || '?recurse=yes;select=*.(xsl|xslt);on-error=warning')"/>  
    </xsl:variable>
    <xsl:call-template name="text-output">
      <xsl:with-param name="total" select="sum($results ! ?total)"/>
      <xsl:with-param name="good" select="sum($results ! ?good)"/>
      <xsl:with-param name="bad" select="sum($results ! ?bad)"/>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>