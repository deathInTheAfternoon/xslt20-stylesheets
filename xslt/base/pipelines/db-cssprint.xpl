<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns:dbp="http://docbook.github.com/ns/pipeline"
                xmlns:pxp="http://exproc.org/proposed/steps"
                xmlns:cx="http://xmlcalabash.com/ns/extensions"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                name="main" version="1.0"
                exclude-inline-prefixes="c cx db dbp pxp"
                type="dbp:docbook-css-print">
<p:input port="source" sequence="true" primary="true"/>
<p:input port="parameters" kind="parameter"/>
<p:output port="result" sequence="true" primary="true">
  <p:pipe step="process-secondary" port="result"/>
</p:output>
<p:output port="secondary" sequence="true" primary="false">
  <p:empty/>
</p:output>
<p:serialization port="result" method="text" encoding="utf-8"/>

<p:option name="style" select="'docbook'"/>
<p:option name="postprocess" select="''"/>
<p:option name="pdf" select="'/tmp/db-cssprint.pdf'"/>
<p:option name="css" select="''"/>

<p:declare-step type="cx:message">
  <p:input port="source" sequence="true"/>
  <p:output port="result" sequence="true"/>
  <p:option name="message" required="true"/>
</p:declare-step>

<p:declare-step type="cx:css-formatter">
  <p:input port="source" primary="true"/>
  <p:input port="css" sequence="true"/>
  <p:input port="parameters" kind="parameter"/>
  <p:output port="result" primary="false"/>
  <p:option name="href" required="true"/>
  <p:option name="content-type"/>
</p:declare-step>

<p:choose name="final-pass">
  <p:when test="$style = 'docbook'">
    <p:output port="result" primary="true"/>
    <p:output port="secondary" sequence="true">
      <p:pipe step="html-docbook" port="secondary"/>
    </p:output>
    <p:xslt name="html-docbook">
      <p:input port="stylesheet">
        <p:document href="../html/final-pass.xsl"/>
      </p:input>
    </p:xslt>
  </p:when>
  <p:when test="$style = 'slides'">
    <p:output port="result" primary="true"/>
    <p:output port="secondary" sequence="true">
      <p:pipe step="html-slides" port="secondary"/>
    </p:output>
    <p:xslt name="html-slides">
      <p:input port="stylesheet">
        <p:document href="../../slides/html/plain.xsl"/>
      </p:input>
    </p:xslt>
  </p:when>
  <p:when test="$style = 'slide-notes'">
    <p:output port="result" primary="true"/>
    <p:output port="secondary" sequence="true">
      <p:pipe step="html-slides-notes" port="secondary"/>
    </p:output>
    <p:xslt name="html-slides-notes">
      <p:input port="stylesheet">
        <p:document href="../../slides/html/plain-notes.xsl"/>
      </p:input>
    </p:xslt>
  </p:when>
  <p:when test="$style = 'publishers'">
    <p:output port="result" primary="true"/>
    <p:output port="secondary" sequence="true">
      <p:pipe step="html-publishers" port="secondary"/>
    </p:output>
    <p:xslt name="html-publishers">
      <p:input port="stylesheet">
        <p:document href="../../publishers/html/publishers.xsl"/>
      </p:input>
    </p:xslt>
  </p:when>
  <p:when test="$style = 'chunk'">
    <p:output port="result" primary="true"/>
    <p:output port="secondary" sequence="true">
      <p:pipe step="html-chunk" port="secondary"/>
    </p:output>
    <p:xslt name="html-chunk">
      <p:input port="stylesheet">
        <p:document href="../html/chunk.xsl"/>
      </p:input>
    </p:xslt>
  </p:when>
  <p:otherwise xmlns:exf="http://exproc.org/standard/functions">
    <p:output port="result" primary="true"/>
    <p:output port="secondary" sequence="true">
      <p:pipe step="html-user-cwd" port="secondary"/>
    </p:output>
    <!-- This relies on an XML Calabash extension function as a user
         convenience. I'm open to suggestions... -->
    <p:load name="load-style">
      <p:with-option name="href" select="resolve-uri($style, exf:cwd())"/>
    </p:load>
    <p:xslt name="html-user-cwd">
      <p:input port="source">
        <p:pipe step="main" port="source"/>
      </p:input>
      <p:input port="stylesheet">
        <p:pipe step="load-style" port="result"/>
      </p:input>
    </p:xslt>
  </p:otherwise>
</p:choose>

<p:choose name="postprocess">
  <p:when test="$postprocess = ''">
    <p:output port="result" sequence="true" primary="true"/>
    <p:output port="secondary" sequence="true">
      <p:pipe step="secondary" port="result"/>
    </p:output>
    <p:identity name="secondary">
      <p:input port="source">
        <p:pipe step="final-pass" port="secondary"/>
      </p:input>
    </p:identity>
    <p:identity>
      <p:input port="source">
        <p:pipe step="final-pass" port="result"/>
      </p:input>
    </p:identity>
  </p:when>
  <p:otherwise xmlns:exf="http://exproc.org/standard/functions">
    <p:output port="result" sequence="true" primary="true">
      <p:pipe step="primary" port="result"/>
    </p:output>
    <p:output port="secondary" sequence="true">
      <p:pipe step="secondary" port="result"/>
    </p:output>

    <p:load name="load-style">
      <p:with-option name="href" select="resolve-uri($postprocess, exf:cwd())"/>
    </p:load>

    <p:xslt name="primary">
      <p:input port="stylesheet">
        <p:pipe step="load-style" port="result"/>
      </p:input>
      <p:input port="source">
        <p:pipe step="final-pass" port="result"/>
      </p:input>
    </p:xslt>

    <p:for-each name="secondary">
      <p:iteration-source>
        <p:pipe step="final-pass" port="secondary"/>
      </p:iteration-source>
      <p:output port="result"/>

      <p:xslt>
        <p:input port="stylesheet">
          <p:pipe step="load-style" port="result"/>
        </p:input>
      </p:xslt>
    </p:for-each>
  </p:otherwise>
</p:choose>

<p:choose name="load-css">
  <p:when test="$css = ''">
    <p:output port="result" sequence="true"/>
    <p:identity>
      <p:input port="source">
        <p:inline>
          <c:result content-type="text/css">/* CSS */</c:result>
        </p:inline>
      </p:input>
    </p:identity>
  </p:when>
  <p:otherwise xmlns:exf="http://exproc.org/standard/functions">
    <p:output port="result" sequence="true"/>

    <p:add-attribute match="/*" attribute-name="href">
      <p:input port="source">
        <p:inline>
          <c:request override-content-type="text/css"
                     method="GET"/>
        </p:inline>
      </p:input>
      <p:with-option name="attribute-value"
                     select="resolve-uri($css, exf:cwd())"/>
    </p:add-attribute>

    <p:http-request/>
  </p:otherwise>
</p:choose>

<cx:css-formatter name="process-secondary" content-type="application/pdf">
  <p:input port="source">
    <p:pipe step="postprocess" port="result"/>
  </p:input>
  <p:input port="css">
    <p:pipe step="load-css" port="result"/>
  </p:input>
  <p:with-option xmlns:exf="http://exproc.org/standard/functions"
                 name="href" select="resolve-uri($pdf, exf:cwd())"/>
</cx:css-formatter>

</p:declare-step>