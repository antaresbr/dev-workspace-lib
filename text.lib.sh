#!/bin/bash 

if [ -z "$TEXT_LIB_SH" ]
then

TEXT_LIB_SH="loaded"

#-- text_concat : Concatenate strints
#   parameters
#     zSep : Glue
#     ...  : Texts to concatenate
text_concat () {
  local zSep="$1" && shift
  
  local zText=""

  while [ $# -gt 0 ]
  do
    if [ "$1" != "" ]
    then
      [ -n "$zText" ] && zText="${zText}${zSep}"
      local zText="${zText}$1"
    fi
    shift
  done
  
  echo -n "$zText"
}


#-- text_leftTrim : Left space trim
#   parameters
#     zStr : Source text
text_leftTrim () {
  local zStr="$(echo -n "$1" | sed -e 's/^[[:space:]]*//')"
  echo -n "$zStr"
}


#-- text_rightTrim : Right space trim
#   parameters
#     zStr : Source text
text_rightTrim () {
  local zStr="$(echo -n "$1" | sed -e 's/[[:space:]]*$//')"
  echo -n "$zStr"
}


#-- text_trim : Right and left space trim
#   parameters
#     zStr : Source text
text_trim () {
  local zStr="$1"
  local zStr=$(text_leftTrim "$zStr")
  local zStr=$(text_rightTrim "$zStr")
  echo -n "$zStr"
}


#-- text_strPad : String pad
#   parameters
#     zStr   : Source text
#     zChar  : Character
#     zLen   : Desired length
#     zPos   : Pad side: [ RIGHT | left ]
#     zTrunc : Flag to truncate final text do zLen: [ FALSE | true]
text_strPad () {
  local zStr="$1" && shift
  local zChar="$1" && shift
  local zLen="$1" && shift
  local zPos="${1^^}" && shift
  local zTrunc="${1^^}" && shift
  
  [ "$zPos" != "LEFT" ] && local zPos="RIGHT"
  [ "$zTrunc" != "TRUE" ] && local zTrunc="FALSE"
  
  local outStr="$zStr"
  
  while [ ${#outStr} -lt $zLen ]; do
    if [ "$zPos" == "LEFT" ]
    then
      local outStr="${zChar}${outStr}"
    else
      local outStr="${outStr}${zChar}"
    fi
    if [ ${#outStr} -gt $zLen ]
    then
      local zTrunc="TRUE"
    fi
  done
  
  if [ "$zTrunc" == "TRUE" ]
  then
    if [ "$zPos" == "LEFT" ]
    then
      local outStr="${outStr:(-$zLen)}"
    else
      local outStr="${outStr:0:$zLen}"
    fi
  fi
  
  echo -n "$outStr"
}


#-- text_rightSpaceFill : Fill text with trailing spaces
#   parameters
#     zStr   : Source text
#     zLen   : Desired length
#     zTrunc : Flag to truncate final text do zLen: [ FALSE | true]
text_rightSpaceFill () {
  local zStr="$1"
  local zLen="$2"
  local zTrunc="$3"
  
  local rs=$(text_strPad "$zStr" " " "$zLen" "RIGHT" "$zTrunc")
  echo -n "${rs}"
}


#-- text_leftSpaceFill : Fill text with leading spaces
#   parameters
#     zStr   : Source text
#     zLen   : Desired length
#     zTrunc : Flag to truncate final text do zLen: [ FALSE | true]
text_leftSpaceFill () {
  local zStr="$1"
  local zLen="$2"
  local zTrunc="$3"
  
  local rs=$(text_strPad "$zStr" " " "$zLen" "LEFT" "$zTrunc")
  echo -n "${rs}"
}


#-- text_leftZeroFill : Fill text with leading zeros
#   parameters
#     zStr   : Source text
#     zLen   : Desired length
#     zTrunc : Flag to truncate final text do zLen: [ FALSE | true]
text_leftZeroFill () {
  local zStr="$1"
  local zLen="$2"
  local zTrunc="$3"

  echo $(text_strPad "$zStr" "0" "$zLen" "LEFT" "$zTrunc")
}


#-- text_leftZeroTrim : Trim leading zeros
#   parameters
#     zStr : Source text
text_leftZeroTrim () {
  local zStr="$(echo -n "$1" | sed -e 's/^0*//')"
  echo -n "$zStr"
}


#-- text_random : Random Text
#   parameters
#     zLen     : Desired length
#     zPattern : Patter to be used: [A-Za-z0-9]
text_random () {
  local zLen="$1"
  local zPattern="$2"

  [ -z "$zPattern" ] && local zPattern="A-Za-z0-9"
  
  echo -n "$(< /dev/urandom tr -dc "${zPattern}" | head --bytes="${zLen}")"
}


#-- text_pwgen : Random password
#   parameters
#     zLen     : Desired length
#     zPattern : Patter to be used: [A-Za-z0-9\\!\\@\\#\\%\\(\\)\\[\\]\\-\\+\\_]
text_pwgen() {
  local zLen="$1"
  local zPattern="$2"

  [ -z "${zLen}" ] && local zLen=16
  [ -z "$zPattern" ] && local zPattern="A-Za-z0-9\\!\\@\\#\\%\\(\\)\\[\\]\\-\\+\\_"

  echo -n "$(< /dev/urandom tr -dc "${zPattern}" | head --bytes=${zLen})"
}


#-- text_escapedHex : Scape text to hexadecimal values
#   parameters
#     zStr : Texto origem
text_escapedHex () {
  local local zStr="$1" && shift
  if [ "$#" -gt 0 ]
  then
    local zPrefix="$1"
  else
    local zPrefix='\x'
  fi

  local zOut=""

  local len=${#zStr}
  for (( i=0; i<${len}; i++ ))
  do
    local ch="${zStr:${i}:1}"
    local zOut="${zOut}${zPrefix}$(printf '%x' "'${ch}")"
  done

  echo -n "${zOut}"
}


#-- text_inStr : Search for substring in string
#   parameters
#     zStr           : Source text
#     zTarget        : Target substring
#     zCaseSensitive : Flag to ignore case [ FALSE | true]
#   returns
#     TRUE  : zTarget was found
#     FALSE : zTarget was NOT found
text_inStr () {
  local zStr="$1" && shift
  local zTarget="$1" && shift
  local zCaseSensitive="${1^^}" && shift
  
  if [ "$zCaseSensitive" != "TRUE" ]
  then
    local zCaseSensitive="FALSE"
    local zStr="${zStr^^}"
    local zTarget="${zTarget^^}"
  fi
  
  if [[ "$zStr" == *"$zTarget"* ]]
  then
    echo -n "TRUE"
  else
    echo -n "FALSE"
  fi
}


#-- text_isInteger : Test if given text is integer
#   parameters
#     zStr  : Source text
#   retorna
#     TRUE  : zStr is integer
#     FALSE : zStr is NOT integer
text_isInteger () {
  local zStr="$1"
  
  if [ "$zStr" != "" ] && [[ $1 =~ ^[0-9]+$ ]]
  then
    echo -n "TRUE"
  else
    echo -n "FALSE"
  fi
}


#-- text_getUInteger : Get unsigned integer from string
#   parameters
#     zStr : Source text
text_getUInteger () {
  echo -n "$1" | sed 's/[^0-9]//g'
}


#-- text_implode : Implode texts
#   parameters
#     zSep : Separator, default: '|'
#     ...  : Tests to implode
text_implode () {
  local zSep="$1" && shift
  [ -z "${zSep}" ] && local zSep="|"

  local rs=""
  while [ $# -gt 0 ]
  do
    [ -n "${rs}" ] && local rs="${rs}${zSep}"
    local rs="${rs}$1"
    shift
  done
  echo -n "${rs}"
}


#-- text_explode : Explode text in lines
#   parameters
#     zSep : Separator, default: '|'
#     zStr : Source text
text_explode () {
  local zSep="$1" && shift
  local zStr="$1" && shift

  [ -z "${zSep}" ] && local zSep="|"

  local rs=""
  local ifs_backup="${IFS}"
  IFS="${zSep}"
  for item in ${zStr}
  do
    [ -n "${rs}" ] && local rs="${rs}"$'\n'
    local rs="${rs}${item}"
  done
  IFS="${ifs_backup}"

  echo -n "${rs}"
}


#-- text_reverse : Invert text based on a separator
#   parameters
#     zSep : Separator, default: '|'
#     zStr : Source text
text_reverse () {
  local zSep="$1" && shift
  local zStr="$1" && shift

  [ -z "${zSep}" ] && local zSep="|"

  local rs=""
  local exploded="$(text_explode "${zSep}" "${zStr}")"
  local ifs_backup="${IFS}"
  IFS=$'\n'
  for piece in ${exploded}
  do
    [ -n "${rs}" ] && local rs="${zSep}${rs}"
    local rs="${piece}${rs}"
  done
  IFS="${ifs_backup}"

  echo -n "${rs}"
}

fi
