<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/TR/WD-xsl">

  <xsl:template match="page">
    <TABLE BORDER="1" WIDTH="100%">
      <TR>
        <TH COLSPAN="2" BGCOLOR="#CCCCCC"><xsl:value-of select="@name"/></TH>
      </TR>
      
      <TR>
        <TD WIDTH="40%" ALIGN="RIGHT">Page Frequency:</TD>
        <TD><xsl:value-of select="pageFrequency"/></TD>
      </TR>
      <TR>
        <TD WIDTH="40%" ALIGN="RIGHT">Response Frequency:</TD>
        <TD><xsl:value-of select="responseFrequency"/></TD>
      </TR>
      <TR>
        <TD WIDTH="40%" ALIGN="RIGHT">Page Delivery Volume:</TD>
        <TD><xsl:value-of select="pageDeliveryVolume"/></TD>
      </TR>
      <TR>
        <TD WIDTH="40%" ALIGN="RIGHT">Relative Time Consumption:</TD>
        <TD><xsl:value-of select="relativeTimeConsumption"/></TD>
      </TR>

      <TR><TD COLSPAN="2" WIDTH="100%"></TD></TR>

	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Maximum Response Size:</TD>
	  <TD><xsl:value-of select="largestResponseSize"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Minimum Response Size:</TD>
	  <TD><xsl:value-of select="smallestResponseSize"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Average Response Size:</TD>
	  <TD><xsl:value-of select="averageResponseSize"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Total Response Size:</TD>
	  <TD>
	    <xsl:value-of select="totalResponseSize"/> / 
	    <xsl:value-of select="totalZippedSize"/> zipped
	  </TD>
	</TR>
	
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Maximum Duration:</TD>
	  <TD><xsl:value-of select="maximumDuration"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Minimum Duration:</TD>
	  <TD><xsl:value-of select="minimumDuration"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Average Duration:</TD>
	  <TD><xsl:value-of select="averageDuration"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Total Duration:</TD>
	  <TD><xsl:value-of select="totalDuration"/></TD>
	</TR>

	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Number of Zipped Response's:</TD>
	  <TD><xsl:value-of select="numberOfZippedResponses"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Total Number of Response's:</TD>
	  <TD><xsl:value-of select="totalResponseCount"/></TD>
	</TR>
    </TABLE>
  </xsl:template>
  
  <xsl:template match="pages">
    <TABLE BORDER="0" CELLPADDING="4" WIDTH="100%">
      <xsl:for-each select="page" order-by="@name">
        <TR>
	  <TD>
	    <xsl:apply-templates select="."/>
	  </TD>
        </TR>
      </xsl:for-each>
    </TABLE>
  </xsl:template>
  
  <xsl:template match="application">
    <HEAD>
      <TITLE>Statistics about <xsl:value-of select="@name"/></TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
      <H3>
	Statistics about <xsl:value-of select="@name"/>
        from
	<xsl:value-of select="statisticsDate"/>
      </H3>
      
      <CENTER>
      <TABLE BORDER="1" WIDTH="98%">
	<TR>
	  <TH BGCOLOR="#AAAAAA" COLSPAN="2">General Statistics</TH>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Instance Uptime:</TD>
	  <TD>
	    <xsl:value-of select="instanceUptime"/>s / 
	    <xsl:value-of select="instanceUptimeInHours"/>h
	  </TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Load:</TD>
	  <TD><xsl:value-of select="instanceLoad"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Start-Time:</TD>
	  <TD><xsl:value-of select="instanceStartDate"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Virtual Memory Size:</TD>
	  <TD>
            <xsl:value-of select="memory/VmSize"/> bytes,
            <xsl:eval>
              formatNumber(this.selectNodes('memory/VmSize')[0].nodeTypedValue
                            / 1024 / 1024, '#.#')
            </xsl:eval> MB
          </TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Resident Memory Size:</TD>
	  <TD>
            <xsl:value-of select="memory/VmRSS"/> bytes,
            <xsl:eval>
              formatNumber(this.selectNodes('memory/VmRSS')[0].nodeTypedValue
                            / 1024 / 1024, '#.#')
            </xsl:eval> MB
          </TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Data Memory Size:</TD>
	  <TD>
            <xsl:value-of select="memory/VmData"/> bytes,
            <xsl:eval>
              formatNumber(this.selectNodes('memory/VmData')[0].nodeTypedValue
                            / 1024 / 1024, '#.#')
            </xsl:eval> MB
          </TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Library Memory Size:</TD>
	  <TD>
            <xsl:value-of select="memory/VmLib"/> bytes,
            <xsl:eval>
              formatNumber(this.selectNodes('memory/VmLib')[0].nodeTypedValue
                            / 1024 / 1024, '#.#')
            </xsl:eval> MB
          </TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Stack Size:</TD>
	  <TD><xsl:value-of select="memory/VmStk"/> bytes</TD>
	</TR>
      </TABLE>
      <BR/>
      
      <TABLE BORDER="1" WIDTH="98%">
	<TR>
	  <TH BGCOLOR="#AAAAAA" COLSPAN="2">Durations</TH>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Maximum Duration:</TD>
	  <TD><xsl:value-of select="maximumDuration"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Minimum Duration:</TD>
	  <TD><xsl:value-of select="minimumDuration"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Average Duration:</TD>
	  <TD><xsl:value-of select="averageDuration"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Total Duration:</TD>
	  <TD><xsl:value-of select="totalDuration"/></TD>
	</TR>
      </TABLE>
      <BR/>

      <TABLE BORDER="1" WIDTH="98%">
	<TR>
	  <TH BGCOLOR="#AAAAAA" COLSPAN="2">Sizes (in bytes)</TH>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Maximum Response Size:</TD>
	  <TD><xsl:value-of select="largestResponseSize"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Minimum Response Size:</TD>
	  <TD><xsl:value-of select="smallestResponseSize"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Average Response Size:</TD>
	  <TD><xsl:value-of select="averageResponseSize"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Total Response Size:</TD>
	  <TD>
	    <xsl:value-of select="totalResponseSize"/> / 
	    <xsl:value-of select="totalZippedSize"/> zipped
	  </TD>
	</TR>
      </TABLE>
      <BR/>

      <TABLE BORDER="1" WIDTH="98%">
	<TR>
	  <TH BGCOLOR="#AAAAAA" COLSPAN="2">Responses</TH>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Number of Page Response's:</TD>
	  <TD><xsl:value-of select="pageResponseCount"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Number of Zipped Response's:</TD>
	  <TD><xsl:value-of select="numberOfZippedResponses"/></TD>
	</TR>
	<TR>
	  <TD WIDTH="40%" ALIGN="RIGHT">Total Number of Response's:</TD>
	  <TD><xsl:value-of select="totalResponseCount"/></TD>
	</TR>
      </TABLE>
      <BR/>
      
      <TABLE BORDER="1" WIDTH="98%">
	<TR>
	  <TH BGCOLOR="#AAAAAA">Pages</TH>
	</TR>
        <TR>
	  <TD><xsl:apply-templates select="pages"/></TD>
	</TR>
      </TABLE>
      
      </CENTER>
    </BODY>
  </xsl:template>
  
  <xsl:template match="/">
    <HTML>
      <xsl:apply-templates select="application"/>
    </HTML>
  </xsl:template>

</xsl:stylesheet>
