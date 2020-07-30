# HOAXCoQS
A routine to calculate @gimsieke’s Highly Opinionated Approximative XSLT Code Quality Score

Basic idea is that this XSLT programs reads in an XSLT program and writes as output a single line of text that includes its HOAXCoQS score.

## Invocation

Single XSLT document

```
saxon -xsl:HOAXCoQS.xslt -s:file:///path/to/dir/stylesheet.xsl
```

Directory

```
saxon -it -xsl:HOAXCoQS.xslt dir=file:///path/to/dir/
```

## Scores

A list of scores can be found in this [Ethercalc sheet](https://ethercalc.org/sg6vohgeswhi). You are engouraged to add your own scores. A CSV dump of that sheet is included in the scores directory. There is no automatic sync set up between the Ethercalc and the dump.
