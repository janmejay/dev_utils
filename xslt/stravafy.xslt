<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  version="1.0">

  <xsl:output omit-xml-declaration="no" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="node()|@*" name="identity">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*">
    <xsl:variable
        name="Keeper_TP"
        select="(name() = 'Trackpoint' and ((position() mod $one_in) = 1))"/>
    <xsl:variable
        name="Not_A_TP"
        select="not(name() = 'Trackpoint')"/>
    <xsl:if test="$Not_A_TP or $Keeper_TP">
      <xsl:call-template name="identity"/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
<!-- Usage: " -->
<!--      xsltproc \ -->
<!--      -o /tmp/short.tcx \ -->
<!--      -param one_in 3 \ -->
<!--      ~/.dev_utils/xslt/stravafy.xslt \ -->
<!--      /home/janmejay/Downloads/28145276412.tcx" -->
