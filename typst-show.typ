#show: doc => article(
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(mainfont)$
  font: ("$mainfont$",),
$endif$
  doc,
)
