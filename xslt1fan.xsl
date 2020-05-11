<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xpath-default-namespace="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
  
  <xsl:import href="HOAXCoQS.xslt"/>
  
  <!-- This is a demo for using weights on the matched elements / attributes, 
  and for excluding them altogether. When an element is to be excluded,
  the template that matches it in 'good' or 'bad' mode should not 
  use xsl:next-match, because then the weight from the matching template
  in the imported HOAXCoQS.xslt will still be added. Instead,
  use <xsl:apply-templates select="* | @*" mode="#current"/> and optionally
  a different weight for the element in question. -->
  
  <xsl:template match="value-of" mode="bad" as="xs:double*">
    <!-- The default weight of 1 is completely nilled. -->
    <xsl:apply-templates select="* | @*" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="for-each" mode="bad" as="xs:double+">
    <!-- The default weight of 1 is replaced by a weight of 0.5. -->
    <xsl:sequence select="0.5"/>
    <xsl:apply-templates select="* | @*" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="apply-imports" mode="good" as="xs:double+">
    <!-- Using apply-imports in XSLT 1 is usually a sign of good 
      programming habits™. However, unlike next-match, it will be 
      considered neutral in the imported stylesheet, because its
      use might be a sign of sticking with old XSLT 1 habits. Yes,
      its use might be justified in XSLT 2+, but most of the time
      next-match will do the trick, too. -->
    <xsl:sequence select="1"/>
    <xsl:apply-templates select="* | @*" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="for-each-group | next-match | sequence | assert | @as | @tunnel" 
    mode="good" as="xs:double*">
    <!-- We need to make sure that they will not be rewarded since they 
      are not allowed in XSLT 1. In this HOAXCoQS customization, only XSLT 1
      programming style is rewarded! --> 
    <xsl:apply-templates select="* | @*" mode="#current"/>
  </xsl:template>

</xsl:stylesheet>