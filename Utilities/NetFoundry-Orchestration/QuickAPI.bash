#!/usr/bin/env bash
####################################################################################################
MyName="${0}"
MyPurpose=("OpenZiti by NetFoundry" "Automation for Quick RESTful Interaction with NetFoundry Cloud")
MyWarranty="This program comes without any warranty, implied or otherwise."
MyLicense="This program has no license."
MyVersion="1.0.20240801 : Nic Fragale @ NetFoundry"
MyCurrentDate="$(date)"
####################################################################################################

##################################################
## DYNAMIC VARIABLES                            ##
##################################################
# These values should be rotated at an interval of choice.
MyMOPClientID="${MyMOPClientID}" # Obtained from NetFoundry Console, Organization, API Accounts.
MyMOPSecret="${MyMOPSecret}" # Obtained from NetFoundry Console, Organization, API Accounts.
# These values should remain static over iterations.
MyNetworkUUID="${MyNetworkUUID}" # Obtained from NetFoundry Console, Networks, ID.
# These values are set by locally exported variables first or defaulted if not available.
FLAG_DebugMode="${FLAG_DebugMode:=FALSE}" # Enable/Disable extra info to be placed into the log/journal.
FLAG_IgnoreColorizer="${FLAG_IgnoreColorizer:=FALSE}" # Enable/Disable color in the printing to screen.
FLAG_LogoMessaging="${FLAG_LogoMessaging:=TRUE}" # Enable/Disable output of the logo.
# The logo ASCII context.
SystemLogo='
          _   __       __   ______                          __
         / | / /___   / /_ / ____/____   __  __ ____   ____/ /_____ __  __
        /  |/ // _ \ / __// /_   / __ \ / / / // __ \ / __  // ___// / / /
       / /|  //  __// /_ / __/  / /_/ // /_/ // / / // /_/ // /   / /_/ /
      /_/ |_/ \___/ \__//_/     \____/ \__,_//_/ /_/ \__,_//_/    \__, /
                                                                 /____/
'

####################################################################################################
# Do not change anything below without knowing what the heck you are doing.
####################################################################################################

##################################################
## ITS A TRAP!                                  ##
##################################################
trap 'COLUMNS=$(COLUMNS= tput cols)' SIGWINCH
trap 'FX_AdvancedPrint "CLEARLINE:1" "END" && FX_GotoExit "2"' SIGINT SIGTERM SIGHUP
#stty -echo -icanon time 0 min 0 2>/dev/null

##################################################
## STATIC VARIABLES                             ##
##################################################
SECONDS="0"
MyMode=""
MyTargetName=""
MyModifications=""
MyMOPAuthURL="https://netfoundry-production-xfjiye.auth.us-east-1.amazoncognito.com/oauth2/token"
MyMOPAccessURL="https://gateway.production.netfoundry.io/core/v2"
MyMOPIdentityURL="https://gateway.production.netfoundry.io/identity/v1"
PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" # Ensures minimal paths are available.
ValidIP="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" # REGEX to match IPv4 addresses.
ValidPrefix="(3[01]|[12][0-9]|[1-9])" # A REGEX string to match a valid CIDR number.
ValidNumber="^[0-9]+$"
AlphaArray=( {A..Z} ) # All letters in the English alphabet (A-Z).
Normal="0" Bold="1" Dimmed="2" Underline="4" Invert="7" Strike="9" # Trigger codes for BASH.
FBlack="30" FRed="31" FGreen="32" FYellow="33" FBlue="34" FMagenta="35" FCyan="36" FLiteGray="37" # Foreground color codes for BASH.
FDarkGray="90" FLiteRed="91" FLiteGreen="92" FLiteYellow="93" FLiteBlue="94" FLiteMagenta="95" FLiteCyan="96" FWhite="37" # Foreground color codes for BASH.
BBlack="40" BRed="41" BGreen="42" BYellow="43" BBlue="44" BMagenta="45" BCyan="46" BLiteGray="47" # Background color codes for BASH.
BDarkGray="100" BLiteRed="101" BLiteGreen="102" BLiteYellow="103" BLiteBlue="104" BLiteMagenta="105" BLiteCyan="106" BWhite="107" # Background color codes for BASH.
export LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8"
export TERM="xterm-256color"
for ((i=0;i<60;i++)); do
    PadLine[0]+='    '
    PadLine[1]+='━━━━'
    PadLine[2]+='····'
    PadLine[3]+='┄┄┄┄'
    PadLine[4]+='╭╮╰╯'
    PadLine[5]+='╰╯╭╮'
    PadLine[6]+='╰╮╭╯'
    PadLine[7]+='╭╯╰╮'
    PadLine[8]+='┬┴┬┴'
    PadLine[9]+='▒▒▒▒'
    PadLine[10]+='0000'
    PadLine[11]+='____'
done # Pad Line generation.
NL='
' # Newline.

##################################################
## USE GNU PROGRAMS IF AVAIABLE                 ##
##################################################
alias sed="$(which gsed)"
alias awk="$(which gawk)"

##################################################
## FUNCTIONS                                    ##
##################################################
#########################
# Exit.
FX_GotoExit() {
  # Expecting 1/ExitCode, 2/ExitDescription.
  local MyExitCode="${1}" MyExitDescription="${2}"
  local MyRESTResponse

  [[ "${MyExitCode}" -ne 99 ]] \
    && FX_AdvancedPrint "COMPLEX:M:-1:1:${Bold};${FWhite};${BBlue}" "CONCLUDE AT $(date) (${SECONDS}s)" "END"

  # Removal of BEARER TOKEN (IF PRESENT).
  if [[ -z "${MyAccessTokenEnv}" ]] && [[ -n "${MyAccessToken}" ]]; then
    # REST API CALL: Release the BEARER TOKEN through a logout.
    FX_AdvancedPrint "COMPLEX:L:20:0:${Bold}" "RELEASE TOKEN"
    MyRESTResponse="$(
      FX_RESTConnect \
        "LOGOUT:${MyAccessToken}" \
        "POST:${MyMOPIdentityURL}/logout"
    )"
    MyAccessToken="$(jq -r '.loggedOut' <<< "${MyRESTResponse}" 2>/dev/null)"
    if [[ -n ${MyAccessToken//null/} ]]; then
      FX_AdvancedPrint "COMPLEX:L:65:0:${Normal}" "OK!" "END"
    else
      FX_AdvancedPrint "COMPLEX:L:65:0:${FRed}" "FAILED!" "END"
    fi
  else
    FX_AdvancedPrint "COMPLEX:L:20:0:${Bold}" "RELEASE TOKEN" "COMPLEX:L:65:0:${Normal}" "NOT REQUIRED" "END"
  fi

  # Exit per the code passed in.
  [[ -n "${MyExitDescription}" ]] \
    && FX_AdvancedPrint "COMPLEX:M:-1:0:${FWhite};${BGray}" "${MyExitDescription}" "END"
  case "${MyExitCode}" in
    "0") FX_AdvancedPrint "COMPLEX:M:-1:1:${Bold};${FWhite};${BBlue}" "DONE (EXIT=${MyExitCode}) (RUNTIME=$((SECONDS/60))m $((SECONDS%60))s)" "END";;
    "99") MyExitCode="0";;
    *) FX_AdvancedPrint "COMPLEX:M:-1:1:${FWhite};${BRed}" "DONE (EXIT=${MyExitCode}) (RUNTIME=$((SECONDS/60))m $((SECONDS%60))s)" "END";;
  esac


  stty sane 2>/dev/null # Return sanity to the input processing.
  echo
  exit "${MyExitCode}" # Bye bye!
}

#########################
# Random Picker.
FX_RandomPicker() {
  # Expecting 1/InputArray.
  local InputArray=( ${1} )

  # Output a random selection from the array.
  echo ${InputArray[$((${RANDOM}%${#InputArray[@]}))]}

  return 0
}

#########################
# Obtain screen info.
FX_ObtainScreenInfo() {
  # Expecting 1/MINCOLWIDTH.
  local MyMinColumnWidth="${1:-0}"
  local MyScreenWidth MyMaxColumnWidth TableColumns i

  # Get the width of the screen at the current moment.
  unset COLUMNS
  MyScreenWidth="$(tput cols)"

  # Process the abilities of the screen.
  if [[ ${MyMinColumnWidth} -le 0 ]] || [[ ${MyMinColumnWidth} -ge ${MyScreenWidth} ]]; then
    # A single column cannot normally exist within the screen or the whole screen is requested as a single column.
    MyMaxColumnWidth="${MyScreenWidth}"
    TableColumns=( "0" )
  else
    # A single column can at least exist normally on this screen.
    # Now obtain how many normal columns can exist within the screen.
    MyMaxColumns="$((${MyScreenWidth}/${MyMinColumnWidth}))"
    # Now obtain the maximum width of each column.
    MyMaxColumnWidth="$((${MyScreenWidth}/${MyMaxColumns}))"
    # Now create an array with the columns enumerated.
    for ((i=0;i<${MyMaxColumns};i++)); do
      TableColumns[${i}]="$((i*${MyMaxColumnWidth}))"
    done
  fi

  # Finally, output the data obtained such that it can be stored as an array.
  echo -e "${MyScreenWidth} ${MyMaxColumnWidth} ${TableColumns[*]}"

  return 0
}

#########################
# Sort a bash array.
FX_ArraySort() {
  # Expecting 1/SortDelimiter, 2/SortByElement, 3/ElementStack.
  local MyStack=( 0 $(($#-3)) ) SortedArray=( "$@" ) SortDelimiter="${1}" SortByElement="${2}"
  local MyBegin MyEnd i MyPivot MySmall MyLarge SortedArray MySortElArr MyPivotElArr

  # Iterate for each element in the stack after the SortByElement.
  SortedArray=( "${SortedArray[@]:2}" )
  while ((${#MyStack[@]})); do
    MyBegin="${MyStack[0]}"
    MyEnd="${MyStack[1]}"
    MyStack=( "${MyStack[@]:2}" )
    MySmall=()
    MyLarge=()
    MyPivot="${SortedArray[${MyBegin}]}"
    MyPivotElArr=( ${MyPivot//${SortDelimiter}/ } )

    # Evaluate the current sorted array.
    for ((i=${MyBegin}+1;i<=${MyEnd};++i)); do
      MySortElArr=( ${SortedArray[${i}]//${SortDelimiter}/ } )
      if FX_TestNumber "${MySortElArr[${SortByElement}]}" && FX_TestNumber "${MyPivotElArr[${SortByElement}]}"; then
        # Both values are numbers and can be be compared as such.
        if [[ ${MySortElArr[${SortByElement}]} -lt ${MyPivotElArr[${SortByElement}]} ]]; then
          MySmall+=( "${SortedArray[${i}]}" )
        else
          MyLarge+=( "${SortedArray[${i}]}" )
        fi
      else
        # One or more of the values are not numbers so string comparison is used.
        if [[ "${MySortElArr[0]}" < "${MyPivotElArr[0]}" ]]; then
          MySmall+=( "${SortedArray[${i}]}" )
        else
          MyLarge+=( "${SortedArray[${i}]}" )
        fi
      fi
    done

    # Prepare the new sorted array for the next iteration.
    SortedArray=( "${SortedArray[@]:0:${MyBegin}}" "${MySmall[@]}" "${MyPivot}" "${MyLarge[@]}" "${SortedArray[@]:${MyEnd}+1}" )

    if ((${#MySmall[@]}>=2)); then
      MyStack+=( "${MyBegin}" "$((${MyBegin}+${#MySmall[@]}-1))" )
    fi
    if ((${#MyLarge[@]}>=2)); then
      MyStack+=( "$((${MyEnd}-${#MyLarge[@]}+1))" "${MyEnd}" )
    fi
  done

  # Return the sorted array.
  for ((i=0;i<${#SortedArray[@]};i++)); do
    echo "${SortedArray[${i}]}"
  done

  return 0
}

#########################
# Colorize Output.
FX_AdvancedPrint() {
  # SubFunction for gathering information on the position of the cursor.
  FXSUB_GetCursorPosition() {
    # Expecting NOINPUT.
    local CursorPositionInput

    # Get the cursor position and strip out decoration data.
    IFS=';' read -sdR -p $'\E[6n' CursorPositionInput[0] CursorPositionInput[1]
    CursorPositionInput[0]="${CursorPositionInput[0]#*[}"

    CursorPositionOutput=( "$((${CursorPositionInput[0]}-1))" "$((${CursorPositionInput[1]}-1))" )
  }

  # SubFunction for manipulating the cursor position.
  FXSUB_ManipulateCursor() {
    # Expecting 1/ACTION, 2/DirectiveA, 3/DirectiveB.
    local ThisAction="${1}" DirectiveA="${2}" DirectiveB="${3}"

    if [[ ${ThisAction} == "MOVETO" ]]; then
      if [[ ${DirectiveA} -eq 0 ]] && [[ ${DirectiveB} -eq 0 ]]; then
        # 0x0 means no movement.
        :
      elif [[ ${DirectiveA} -ne 0 ]] && [[ ${DirectiveB} -ne 0 ]]; then
        # Implicitly move to a LINE and COLUMN.
        FXSUB_GetCursorPosition
        DirectiveA="$((${CursorPositionOutput[0]}+${DirectiveA}))"
        DirectiveB="$((${CursorPositionOutput[1]}+${DirectiveB}))"
        tput cup "${DirectiveA}" "${DirectiveB}"
      elif [[ ${DirectiveA} -eq 0 ]] && [[ ${DirectiveB} -ne 0 ]]; then
        # Implicitly move to a COLUMN and keep the current LINE.
        FXSUB_GetCursorPosition
        DirectiveA="${CursorPositionOutput[0]}"
        DirectiveB="$((${CursorPositionOutput[1]}+${DirectiveB}))"
        [[ ${DirectiveB} -gt 0 ]] \
          && tput cup "${DirectiveA}" "${DirectiveB}"
      elif [[ ${DirectiveA} -ne 0 ]] && [[ ${DirectiveB} -eq 0 ]]; then
        # Implicitly move to a LINE and keep the current COLUMN.
        FXSUB_GetCursorPosition
        DirectiveA="$((${CursorPositionOutput[0]}+${DirectiveA}))"
        DirectiveB="${CursorPositionOutput[1]}"
        [[ ${DirectiveA} -gt 0 ]] \
          && tput cup "${DirectiveA}" "${DirectiveB}"
      fi
    elif [[ ${ThisAction} == "MOVEABSOLUTE" ]]; then
      # Explicitly move to a LINE and COLUMN.
      tput cup "${DirectiveA}" "${DirectiveB}"
    elif [[ ${ThisAction} == "INVISIBLE" ]]; then
      # Make the cursor invisible.
      tput civis
    elif [[ ${ThisAction} == "VISIBLE" ]]; then
      # Make the cursor visible.
      tput cnorm
    elif [[ ${ThisAction} == "CLEARLINE" ]]; then
      # Delete the contents of the current line.
      tput el el1 # Delete from cursor to right.
    elif [[ ${ThisAction} == "CLEARSCREEN" ]]; then
      # Clear the whole screen.
      tput clear
    elif [[ ${ThisAction} == "SAVEPOS" ]]; then
      # Save the cursor position.
      tput sc
    elif [[ ${ThisAction} == "RESTOREPOS" ]]; then
      # Restore the cursor position.
      tput rc
    fi

    return 0
  }

  # Expecting 1/(ARR':')InstSet#1 [2/PrinterContext#1, [3/(ARR':')InstSet#2, 4/Context#2]].
  # Global ConsoleOut.
  local PrinterArray PrinterContext
  local PrintOutSyntax PrintOutTrail DebugOut AllLines CursorPositionOutput MyScreenWidth MyMaxColumnWidth TableColumns
  local itr="0"

  # Invisible cursor while printing.
  FXSUB_ManipulateCursor "INVISIBLE"

  # Parse the instruction set array.
  while [[ -n ${1} ]]; do
    unset PrinterArray PrinterContext
    PrinterArray=( ${1//:/ } )
    PrinterContext="${2}"

    # Element Xn TYPE.
    case "${PrinterArray[0]}" in
      # PrinterArray array structure is "0/TYPE:1/BOUNDARIES:2/PADNUM:3/COLOR".
      "FILL")
        # Expecting elements.
        if [[ ${PrinterArray[1]:=NULLERROR} == "NULLERROR" ]] \
          || [[ ${PrinterArray[2]:=NULLERROR} == "NULLERROR" ]] \
          || [[ ${PrinterArray[3]:=NULLERROR} == "NULLERROR" ]]; then
          break
        fi

        # Handle debug mode.
        [[ ${FLAG_DebugMode} == "TRUE" ]] \
          && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}:${PrinterArray[2]}:${PrinterArray[3]}"
        [[ ${FLAG_ConsoleMode} == "TRUE" ]] \
          && ConsoleOut+="${PadLine[${PrinterArray[2]}]:0:$((${PrinterArray[1]}))}"

        # Handle ignoring of output colors.
        [[ ${FLAG_IgnoreColorizer} == "TRUE" ]] \
          && PrinterArray[3]="${Normal}"

        # Build the current syntax.
        PrintOutSyntax="${PrintOutSyntax}\e[${PrinterArray[3]}m%s${PadLine[${PrinterArray[2]}]:0:$((${PrinterArray[1]}))}\e[1;${Normal}m"
        PrintOutTrail[itr]=""
        ((itr++))
        shift 1
      ;;

      # PrinterArray array structure is "0/TYPE:1/ALIGN:2/BOUNDARIES:3/PADNUM:4/COLOR".
      "COMPLEX")
        # Expecting elements.
        if [[ ${PrinterArray[1]:=NULLERROR} == "NULLERROR" ]] \
          || [[ ${PrinterArray[2]:=NULLERROR} == "NULLERROR" ]] \
          || [[ ${PrinterArray[3]:=NULLERROR} == "NULLERROR" ]] \
          || [[ ${PrinterArray[4]:=NULLERROR} == "NULLERROR" ]] \
          || [[ ${PrinterContext:=NULLERROR} == "NULLERROR" ]]; then
          break
        fi

        # Handle debug mode and console mode.
        [[ ${FLAG_DebugMode} == "TRUE" ]] \
          && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}:${PrinterArray[2]}:${PrinterArray[3]}:${PrinterArray[4]}:${PrinterContext}"
        [[ ${FLAG_ConsoleMode} == "TRUE" ]] \
          && ConsoleOut+="${PrinterContext} "

      # Handle ignoring of output colors.
      [[ ${FLAG_IgnoreColorizer} == "TRUE" ]] \
        && PrinterArray[4]="${Normal}"

        # Process element Xn.
        # End boundary NOT specified.
        if [[ ${PrinterArray[2]} -eq 0 ]]; then
          # No end boundary specified, print everything within the confines of the current screen.
          read -d $'\n' MyScreenWidth MyMaxColumnWidth TableColumns < <(FX_ObtainScreenInfo "0")
          [[ ${#PrinterContext} -le ${MyScreenWidth} ]] \
            && PrinterArray[2]="${#PrinterContext}" \
            || PrinterArray[2]="${MyScreenWidth}"
        elif [[ ${PrinterArray[2]} -lt 0 ]]; then
          # Negative end boundary specified, print everything within the confines of the current screen using the whole screen.
          read -d $'\n' MyScreenWidth MyMaxColumnWidth TableColumns < <(FX_ObtainScreenInfo "0")
          PrinterArray[2]="${MyScreenWidth}"
        fi

        # Analyze.
        if [[ ${#PrinterContext} -gt ${PrinterArray[2]} ]]; then
          # Context is greater than the end boundary, so cut anything past the end boundary and continue without padding.
          PrintOutSyntax="${PrintOutSyntax}\e[${PrinterArray[4]}m%s\e[1;${Normal}m"
          PrintOutTrail[itr]="${PrinterContext:0:$((${PrinterArray[2]}-1))}┄"
        else
          # Special padding (blanks) where printing would otherwise ignore the blank pads.
          if [[ ${PrinterArray[3]} -eq 0 ]]; then
            if [[ ${PrinterArray[1]} == "L" ]]; then
                PrintOutSyntax="${PrintOutSyntax}\e[${PrinterArray[4]}m%s${PadLine[${PrinterArray[3]}]:0:$((${PrinterArray[2]}-${#PrinterContext}))}\e[1;${Normal}m"
            elif [[ ${PrinterArray[1]} == "R" ]]; then
                PrintOutSyntax="${PrintOutSyntax}\e[${PrinterArray[4]}m${PadLine[${PrinterArray[3]}]:0:$((${PrinterArray[2]}-${#PrinterContext}))}%s\e[1;${Normal}m"
            elif [[ ${PrinterArray[1]} == "M" ]]; then
                PrintOutSyntax="${PrintOutSyntax}\e[${PrinterArray[4]}m${PadLine[${PrinterArray[3]}]:0:$(((${PrinterArray[2]}-${#PrinterContext})/2))}%s${PadLine[${PrinterArray[3]}]:0:$((((${PrinterArray[2]}-${#PrinterContext})/2)+((${PrinterArray[2]}-${#PrinterContext})%2)))}\e[1;${Normal}m"
            fi
            PrintOutTrail[itr]="${PrinterContext}"
          else
            if [[ ${PrinterArray[1]} == "L" ]]; then
              PrintOutTrail[itr]="${PrinterContext}${PadLine[${PrinterArray[3]}]:0:$((${PrinterArray[2]}-${#PrinterContext}))}"
            elif [[ ${PrinterArray[1]} == "R" ]]; then
              PrintOutTrail[itr]="${PadLine[${PrinterArray[3]}]:0:$((${PrinterArray[2]}-${#PrinterContext}))}${PrinterContext}"
            elif [[ ${PrinterArray[1]} == "M" ]]; then
              PrintOutTrail[itr]="${PadLine[${PrinterArray[3]}]:0:$(((${PrinterArray[2]}-${#PrinterContext})/2))}${PrinterContext}${PadLine[${PrinterArray[3]}]:0:$((((${PrinterArray[2]}-${#PrinterContext})/2)+((${PrinterArray[2]}-${#PrinterContext})%2)))}"
            fi
            PrintOutSyntax="${PrintOutSyntax}\e[${PrinterArray[4]}m%s\e[1;${Normal}m"
          fi
        fi
        ((itr++))
        shift 2
      ;;

      # PrinterArray array structure is "0/TYPE:1/LINES:2/COLS".
      "MOVETO"|"MOVEABSOLUTE")
        # Expecting elements.
        if [[ ${PrinterArray[1]:=NULLERROR} == "NULLERROR" ]] \
          && [[ ${PrinterArray[2]:=NULLERROR} == "NULLERROR" ]]; then
          break
        fi

        # Handle debug mode.
        [[ ${FLAG_DebugMode} == "TRUE" ]] \
          && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}:${PrinterArray[2]}"

        # Flush the current queue before beginning.
        if [[ ${PrintOutSyntax} != "" ]] || [[ ${#PrintOutTrail[@]} -ne 0 ]]; then
          printf "${PrintOutSyntax}" "${PrintOutTrail[@]}"
          unset PrintOutSyntax PrintOutTrail
        fi

        # Request the cursor movement.
        FXSUB_ManipulateCursor "${PrinterArray[0]}" "${PrinterArray[1]}" "${PrinterArray[2]}"
        shift 1
      ;;

      # PrinterArray array structure is "0/TYPE:1/LINESTOCLEAR".
      "CLEARLINE")
        # Expecting elements.
        if [[ ${PrinterArray[1]:=NULLERROR} == "NULLERROR" ]]; then
          break
        fi

        # Handle debug mode.
        [[ ${FLAG_DebugMode} == "TRUE" ]] \
          && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}"

        # Flush the current queue before beginning.
        if [[ ${PrintOutSyntax} != "" ]] || [[ ${#PrintOutTrail[@]} -ne 0 ]]; then
          printf "${PrintOutSyntax}" "${PrintOutTrail[@]}"
          unset PrintOutSyntax PrintOutTrail
        fi

        if [[ ${PrinterArray[1]} == "ALL" ]]; then
          FXSUB_ManipulateCursor "CLEARSCREEN"
          shift 1
        elif [[ ${PrinterArray[1]} == "ALLSLOW" ]]; then
          FXSUB_GetCursorPosition
          AllLines="${CursorPositionOutput[0]}"
          for ((i=0;i<${AllLines};i++)); do
            FXSUB_ManipulateCursor "CLEARLINE" # Delete the contents of this line.
            FXSUB_ManipulateCursor "MOVETO" "-1" "0" # Go up one line.
            sleep 0.01 # Wait.
          done
          FXSUB_ManipulateCursor "CLEARSCREEN"
          shift 1
        else
          for ((i=0;i<${PrinterArray[1]};i++)); do
            FXSUB_ManipulateCursor "CLEARLINE" # Delete the contents of this line.
            FXSUB_ManipulateCursor "MOVETO" "-1" "0" # Go up one line.
          done
          shift 1
        fi
      ;;

      # PrinterArray array structure is "0/TYPE:1/TIMETOWAIT".
      "WAIT")
        # Expecting elements.
        if [[ ${PrinterArray[1]:=NULLERROR} == "NULLERROR" ]]; then
          break
        fi

        # Handle debug mode.
        [[ ${FLAG_DebugMode} == "TRUE" ]] \
          && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}"

        # Flush the current queue before beginning.
        if [[ ${PrintOutSyntax} != "" ]] || [[ ${#PrintOutTrail[@]} -ne 0 ]]; then
          printf "${PrintOutSyntax}" "${PrintOutTrail[@]}"
          unset PrintOutSyntax PrintOutTrail
        fi

        # Wait the required seconds.
        sleep "${PrinterArray[1]}"
        shift 1
      ;;

      # PrinterArray array structure is "0/TYPE".
      "FLUSHCONSOLE")
        (echo "${ConsoleOut}" >> /dev/console) 2>/dev/null
        ConsoleOut=""
        shift 1
      ;;

      # PrinterArray array structure is "0/TYPE".
      "NEXT"|"END"|*)
        # Handle debug mode.
        [[ ${FLAG_DebugMode} == "TRUE" ]] \
          && DebugOut="${DebugOut}/${PrinterArray[0]}"
        if [[ ${PrinterArray[0]} == "NEXT" ]]; then
          PrintOutSyntax="${PrintOutSyntax}\n"
          [[ ${FLAG_ConsoleMode} == "TRUE" ]] \
            && ConsoleOut+="${NL}"
          ((itr++))
          shift 1
        elif [[ ${PrinterArray[0]} == "END" ]]; then
          PrintOutSyntax="${PrintOutSyntax}\n"
          [[ ${FLAG_ConsoleMode} == "TRUE" ]] \
            && ConsoleOut+="${NL}"
          break
        else
          PrintOutSyntax="${PrintOutSyntax}%s"
          PrintOutTrail[itr]="${PrinterArray[0]}"
          [[ ${FLAG_ConsoleMode} == "TRUE" ]] \
            && ConsoleOut+="${PrinterContext} "
          ((itr++))
          shift 1
        fi
      ;;
    esac
  done

  # Handle debug mode and console mode.
  [[ ${FLAG_DebugMode} == "TRUE" ]] \
    && logger -t "${MyName}" "${FUNCNAME[1]}${DebugOut}"

  # Request a print of the gathered syntax and context.
  printf "${PrintOutSyntax}" "${PrintOutTrail[@]}"

  # Make cursor visible again.
  FXSUB_ManipulateCursor "VISIBLE"

  return 0
}

#########################
# Variable Response.
FX_GetResponse() {
    local InputQuestion="${1}" DefaultAnswer="${2}"
    local REPLY
    unset REPLY UserResponse

    # Do not allow blank or passed in NONE to be an answer.
    while :; do

        # A request for RESPONSE is a statement for an arbitrary answer.
        FX_AdvancedPrint "COMPLEX:L:20:0:${Bold};${FGreen}" "RESPONSE" "COMPLEX:L:0:0:${Normal}" "${InputQuestion} [QUIT=QUIT]"

        # Get the answer.
        read -rp "Response? [DEFAULT=\"${DefaultAnswer}\"] > "
        if [[ ${REPLY:-NONE} == "NONE" ]] && [[ ${DefaultAnswer:-NONE} != "NONE" ]]; then
            UserResponse="${DefaultAnswer}"
        elif [[ ${REPLY:-NONE} == "NONE" ]] && [[ ${DefaultAnswer:-NONE} == "NONE" ]]; then
            FX_AdvancedPrint "COMPLEX:L:20:0:${Bold};${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Invalid response \"${REPLY:-NO INPUT}\", try again."
            sleep 1
            continue
        elif [[ ${REPLY:-NONE} == "QUIT" ]]; then
            return 99
        else
            UserResponse="${REPLY}"
        fi

        return 0

    done
}

#########################
# Yes/No Response.
FX_GetYorN() {
    local InputQuestion="${1}" DefaultAnswer="${2}" TimerVal="${3}"
    unset REPLY UserResponse

    # Loop until a decision is made.
    while :; do

        # Get the answer.
        if [[ ${TimerVal} ]]; then
            # A request for YES OR NO is a question only.
            FX_AdvancedPrint "COMPLEX:L:20:0:${Bold};${FGreen}" "YES OR NO" "COMPLEX:L:0:0:${Normal}" "${InputQuestion}"
            ! read -rt "${TimerVal}" -p " [DEFAULT=\"${DefaultAnswer}\"] [TIMEOUT=${TimerVal}s] > " \
                && printf '%s\n' "[TIMED OUT, DEFAULT \"${DefaultAnswer}\" SELECTED]" \
                && sleep 1
        elif [[ ${InputQuestion} == "SPECIAL-PAUSE" ]]; then
            read -rp "Press ENTER to Continue > "
            unset REPLY
            return 0
        else
            # A request for YES OR NO is a question only.
            FX_AdvancedPrint "COMPLEX:L:20:0:${Bold};${FGreen}" "YES OR NO" "COMPLEX:L:0:0:${Normal}" "${InputQuestion}"
            read -rp " [DEFAULT=\"${DefaultAnswer}\"] > "
        fi

        # If there was no reply, take the default.
        [[ ${REPLY:-NONE} == "NONE" ]] \
            && REPLY="${DefaultAnswer}"

        # Find out which reply was given.
        case ${REPLY} in
            Y|YE|YES|YEs|Yes|yes|ye|y)
                unset REPLY
                return 0
            ;;
            N|NO|No|no|n)
                unset REPLY
                return 1
            ;;
            QUIT)
                return 99
            ;;
            *)
                FX_AdvancedPrint "COMPLEX:L:20:0:${Bold};${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Invalid response \"${REPLY:-NO INPUT}\", try again."
                unset REPLY
                sleep 1
                continue
            ;;
        esac

    done
}

#########################
# Selection Response.
FX_GetSelection() {
    local i REPLY SelectionList TMP_DefaultAnswer
    local InputQuestion InputAllowed InputAllowed DefaultAnswer MaxLength
    InputQuestion="${1}"
    InputAllowed=( "QUIT" ${2} )
    DefaultAnswer="${3}"
    TimerVal="${4}"
    MaxLength="0"
    unset SELECTION UserResponse PS3

    # Prompt text.
    PS3="#? > "

    # Make the selections easy to read.
    for ((i=0;i<${#InputAllowed[@]};i++)); do
        if [[ ${#InputAllowed[${i}]} -gt 65 ]]; then
            MaxLength="65"
        elif [[ ${#InputAllowed[${i}]} -gt ${MaxLength} ]]; then
            MaxLength="${#InputAllowed[${i}]}"
        fi
    done

    # Build the list in a readable format.
    for ((i=0;i<${#InputAllowed[@]};i++)); do
        SelectionList[${i}]="$(printf "%-${MaxLength}s\n" "${InputAllowed[${i}]}")"
    done

    # Loop until a decision is made.
    while :; do

        # If there is a default, a prompt will appear to accept it or move to the selection.
        if [[ ${DefaultAnswer:-NONE} != "NONE" ]]; then
            # This is a statement for a request of a selection.
            FX_AdvancedPrint "COMPLEX:L:20:0:${Bold};${FGreen}" "SELECTION" "COMPLEX:L:0:0:${Normal}" "${InputQuestion}" "END"
            TMP_DefaultAnswer=${DefaultAnswer}1
            FX_GetYorN "Keep selection of \"${DefaultAnswer}\"?" "Yes" "${TimerVal}" \
                && UserResponse=${TMP_DefaultAnswer} \
                && break
        fi

        # Otherwise, get the selection.
        FX_AdvancedPrint "COMPLEX:L:20:0:${Bold};${FGreen}" "SELECTION" "COMPLEX:L:0:0:${Normal}" "${InputQuestion}" "END"
        COLUMNS="1" # Force select statement into a single column.
        select SELECTION in ${SelectionList[@]}; do
            if { [[ "${REPLY}" == "QUIT" ]]; } || { [[ 1 -le "${REPLY}" ]] && [[ "${REPLY}" -le ${#SelectionList[*]} ]]; }; then
                case ${REPLY} in
                    1|"QUIT")
                        return 99
                    ;;
                    *)
                        UserResponse="${InputAllowed[$((REPLY-1))]}"
                        return 0
                    ;;
                esac
            else
                FX_AdvancedPrint "COMPLEX:L:20:0:${Bold};${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Invalid response \"${REPLY:-NO INPUT}\", try again." "END"
                sleep 1
            fi
            FX_AdvancedPrint "COMPLEX:L:20:0:${Bold};${FGreen}" "SELECTION" "COMPLEX:L:0:0:${Normal}" "${InputQuestion}" "END"
        done

    done
}

#########################
# Logo Printer.
FX_LogoMessaging() {
  # Expecting 1/ThisLogo, 2/MessageA, 3/MessageB.
  local ThisLogo="${1}" ThisMessageA="${2}" ThisMessageB="${3}"

  # Check if able to run.
  [[ ${FLAG_LogoMessaging} != "TRUE" ]] \
    && return 0

  # Ensure the logo lines are congruent, then print.
  while IFS=$'\n' read -r EachLine; do
    [[ ${#EachLine} -gt ${MaxLogoLine} ]] \
      && MaxLogoLine="${#EachLine}"
    [[ ${#EachLine} -ne 0 ]] && [[ ${#EachLine} -lt ${MinLogoLine} ]] \
      && MinLogoLine="${#EachLine}"
  done < <(printf '%s\n' "${ThisLogo}")
  ThisColor="$(FX_RandomPicker "${BWhite};${FBlack} ${FRed} ${FGreen} ${FYellow} ${FBlue} ${FMagenta} ${FCyan} ${FLiteGray}")"

  while IFS=$'\n' read -r EachLine; do
    FX_AdvancedPrint \
      "COMPLEX:M:-1:0:${Bold};${ThisColor}" "$(printf "%-${MaxLogoLine}s" "${EachLine}")" "NEXT"
  done < <(printf "%s" "${ThisLogo}")

  # Print login messaging.
  FX_AdvancedPrint \
    "NEXT" "COMPLEX:M:-1:0:${Normal}" "${ThisMessageA}" "NEXT" \
    "COMPLEX:M:-1:0:${Normal}" "${ThisMessageB}" "END"

  return 0
}

#########################
# Print Help.
FX_PrintHelp() {
  # Expecting no input.

  # Print help information.
  FX_AdvancedPrint \
    "COMPLEX:M:-1:1:${Bold};${FWhite};${BBlue}" "PROGRAM HELP MENU" "NEXT" \
    "COMPLEX:L:0:0:${Bold}" "INPUT OPTIONS" "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-h" "COMPLEX:L:0:0:${Normal}" "Display this help menu." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-mER" "COMPLEX:L:0:0:${Normal}" "MODE: ENDPOINT REVIEW." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-mEC" "COMPLEX:L:0:0:${Normal}" "MODE: ENDPOINT CREATE." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-mEM" "COMPLEX:L:0:0:${Normal}" "MODE: ENDPOINT MODIFY." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-mED" "COMPLEX:L:0:0:${Normal}" "MODE: ENDPOINT DELETE." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-mSR" "COMPLEX:L:0:0:${Normal}" "MODE: SERVICE REVIEW." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-mSC" "COMPLEX:L:0:0:${Normal}" "MODE: SERVICE CREATE." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-mSM" "COMPLEX:L:0:0:${Normal}" "MODE: SERVICE MODIFY." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-mSD" "COMPLEX:L:0:0:${Normal}" "MODE: SERVICE DELETE." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-n \"NAME\" (+)" "COMPLEX:L:0:0:${Normal}" "MODIFIER: Target these NAME(s)." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-N \"ATTRIBUTE\" (+)" "COMPLEX:L:0:0:${Normal}" "MODIFIER: Target these ATTRIBUTE(s)." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-i" "COMPLEX:L:0:0:${Normal}" "MODIFIER: Target given NAME(s) using insensitive matching." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-f" "COMPLEX:L:0:0:${Normal}" "MODIFIER: Target given NAME(s) using fuzzy (REGEX) matching. " "COMPLEX:L:0:0:${Underline};${FYellow}" "-underlined and yellow-" "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-F" "COMPLEX:L:0:0:${Normal}" "MODIFIER: Target given NAME(s) using inverted fuzzy (REGEX) matching." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-a \"ATTR\" (+)" "COMPLEX:L:0:0:${Normal}" "MODIFIER: ADD these ATTRIBUTES(s) to given NAME(s) in MODIFY MODE." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-A \"ATTR\" (+)" "COMPLEX:L:0:0:${Normal}" "MODIFIER: REMOVE these ATTRIBUTES(s) from given NAME(s) in MODIFY MODE." "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "${MyName}" "FILL:1:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "-h" "COMPLEX:L:0:0:${Normal}" "Display this help menu." "END"

  FX_AdvancedPrint \
    "COMPLEX:L:0:0:${Bold}" "USAGE EXAMPLES" "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:41:0:${Normal}" "-ifmER -n \"([^f]*fra[^f]*fra[^f])\"" "COMPLEX:L:0:0:${Normal}" "ENDPOINT REVIEW, CASE INSENSITIVE, FUZZY SELECT, ANY NAME MATCHING REGEX \"fra repeated twice\"" "NEXT" \
    "FILL:2:0:${Normal}" "COMPLEX:L:41:0:${Normal}" "-FmER -n \"(john|james).*zde-0[1-2]\"" "COMPLEX:L:0:0:${Normal}" "ENDPOINT REVIEW, CASE SENSITIVE, INVERTED FUZZY SELECT, ANY NAME MATCHING REGEX \"john or james with zde-01 or zde-02\"" "END"
  return 0
}

#########################
# Check the Environment.
FX_CheckEnvironment() {
  # Expecting 1/TYPE.
  local MyType="${1}"
  local MyBashVersion

  IFS='.' read -ra MyBashVersion <<< "${BASH_VERSION}"
  if { [[ ${MyBashVersion[0]} -lt "4" ]]; } || { [[ ${MyBashVersion[0]} -eq "4" ]] && [[ ${MyBashVersion[1]} -lt "3" ]]; }; then
    FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "BASH is not above the required version [${BASH_VERSION}]<[4.3]." "END"
    return 1
  fi

  if [[ ${MyType} == "HELPCONTEXT" ]]; then
    FX_AdvancedPrint \
      "COMPLEX:L:0:0:${Bold}" "ENVIRONMENT OPTIONS [SHELL VARIABLE EXPORTS]" "NEXT" \
      "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "FLAG_DebugMode" "FILL:21:0:${Normal}" "COMPLEX:L:0:0:${Normal}" "Toggle DEBUG printing ON/TRUE or OFF/FALSE (Currently: ${FLAG_DebugMode})." "NEXT" \
      "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "FLAG_IgnoreColorizer" "FILL:21:0:${Normal}" "COMPLEX:L:0:0:${Normal}" "Toggle COLORIZED printing OFF/TRUE or ON/FALSE (Currently: ${FLAG_IgnoreColorizer})." "NEXT" \
      "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "FLAG_LogoMessaging" "FILL:21:0:${Normal}" "COMPLEX:L:0:0:${Normal}" "Toggle LOGO printing ON/TRUE or OFF/FALSE (Currently: ${FLAG_LogoMessaging})." "END"
    [[ -z "${MyMOPSecret}" ]] \
      && FX_AdvancedPrint "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "MyMOPSecret" "FILL:21:0:${Normal}" "COMPLEX:L:0:0:${FRed}" "The NetFoundry MOP API Secret Value (Currently: NOT SET)." "END" \
      || FX_AdvancedPrint "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "MyMOPSecret" "FILL:21:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "The NetFoundry MOP API Secret Value (Currently: SET)." "END"
    [[ -z "${MyMOPClientID}" ]] \
      && FX_AdvancedPrint "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "MyMOPClientID" "FILL:21:0:${Normal}" "COMPLEX:L:0:0:${FRed}" "The NetFoundry MOP API Secret Value (Currently: NOT SET)." "END" \
      || FX_AdvancedPrint "FILL:2:0:${Normal}" "COMPLEX:L:20:0:${Normal}" "MyMOPClientID" "FILL:21:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "The NetFoundry MOP API Secret Value (Currently: SET)." "END"
  elif [[ ${MyType} == "RUNCONTEXT" ]]; then
    [[ -z "${MyMOPSecret}" ]] && [[ -z "${MyMOPClientID}" ]] \
      && FX_AdvancedPrint "COMPLEX:M:-1:0:${FRed}" "ERROR: MOPSECRET=NOT_SET | MOPCLIENTID=NOT_SET" "END" \
      && return 1
    [[ -z "${MyMOPSecret}" ]] && [[ -n "${MyMOPClientID}" ]] \
      && FX_AdvancedPrint "COMPLEX:M:-1:0:${FRed}" "ERROR: MOPSECRET=NOT_SET" "END" \
      && return 1
    [[ -n "${MyMOPSecret}" ]] && [[ -z "${MyMOPClientID}" ]] \
      && FX_AdvancedPrint "COMPLEX:M:-1:0:${FRed}" "ERROR: MOPCLIENTID=NOT_SET" "END" \
      && return 1
  fi

  return 0
}

#########################
# Print debug info.
FX_ShowDebug() {
  # Expecting 1/DEBUGCONTEXT.
  local MyDebugContext="${1}"

  # If in debug mode.
  if [[ ${FLAG_DebugMode} == "TRUE" ]]; then
    FX_AdvancedPrint \
      "NEXT" "COMPLEX:M:-1:1:${Bold};${FYellow};${BBlack}" "DEBUG INFO" "END" >&2
      echo -e "${MyDebugContext}\n" >&2
  fi

  return 0
}

#################################################################################
# JWT Decoder.
function FX_JWTDecoder() {
  # Expecting 1/JWTInput 2/MODE.
  local MyJWTInput="${1:-ERROR}"
  local MyMode="${2:-CHECKONLY}" # VALIDATE/TIMEREMAINING/RENEWCHECK
  local MyCurrentDateEpoch="$(date "+%s")"
  local MyJWTParts MyJWTDecoded MyJWTExpirationEpoch MyJWTConvertedLeft

  # Ensure a JWT was passed in which is at least populated.
  [[ ${MyJWTInput} == "ERROR" ]] || [[ ${#MyJWTInput} -lt 10 ]] \
      && return 1

  # Break the JWT into its parts.
  IFS='.' read -ra MyJWTParts <<< "${MyJWTInput}"
  # Get the decoded header information.
  MyJWTDecoded="$(base64 --decode <<< "${MyJWTParts[1]}=")"
  # Parse out the expiration date from decoded header information.
  MyJWTExpirationEpoch="$(gawk '{print gensub(".*\"exp\":([[:digit:]]+),.*","\\1",1)}' <<< "${MyJWTDecoded}")"
  # Convert the date information (EPOCH) and do maths.
  MyJWTConvertedLeft="$((MyJWTExpirationEpoch-MyCurrentDateEpoch))"

  # Return what was derived based on what is required.
  case ${MyMode} in
  "VALIDATE")
    [[ ${MyJWTConvertedLeft:-ERROR} =~ ${ValidNumber} ]] && [[ ${MyJWTConvertedLeft} -gt 0 ]] \
      && return 0 \
      || return 1
    ;;
    "TIMEREMAINING")
      echo "EXPIRY: $((MyJWTConvertedLeft/86400))d $(((MyJWTConvertedLeft%86400)/3600))h $(((MyJWTConvertedLeft%3600)/60))m $((MyJWTConvertedLeft%60))s"
      return 0
    ;;
    "RENEWCHECK")
      [[ ${MyJWTConvertedLeft:-ERROR} =~ ${ValidNumber} ]] && [[ ${MyJWTConvertedLeft} -lt 300 ]] \
        && return 0 \
        || return 1
    ;;
    *)
      return 1
    ;;
  esac
}

#########################
# Initiate REST Connect.
FX_RESTConnect() {
  # Expecting 1/TYPE[AUTH:USER:SECRET || ACCESS:AUTHTOKEN || LOGOUT:AUTHTOKEN], 2/METHOD:URL, 3/DATA.
  local MyType="${1}" MyMethod="${2}" MyData="${3}"
  local MyRESTResponse MyRESTHeaders MyRESTJSON

  # If in debug mode.
  FX_ShowDebug "${MyType}\n${MyMethod}\n${MyData//*/DATA:${NL}${MyData}}"

  # Depending on the TYPE used, pick a path.
  if [[ ${MyType%%\:*} == "AUTH" ]]; then
    MyRESTResponse="$(
      curl \
        --silent \
        --include \
        --connect-timeout 10 \
        --user "${MyType#*\:}" \
        --request "${MyMethod%%\:*}" "${MyMethod#*\:}" \
        --header "content-type: application/x-www-form-urlencoded" \
        --data "${MyData}" \
        | tr -d '\r'
    )"
  elif [[ ${MyType%%\:*} == "ACCESS" ]]; then
    MyRESTResponse="$(
      curl \
        --silent \
        --include \
        --connect-timeout 10 \
        --request "${MyMethod%%\:*}" "${MyMethod#*\:}" \
        --header "content-type: application/json" \
        --header "Authorization: Bearer ${MyType#*\:}" \
        --data "${MyData}" \
        | tr -d '\r'
    )"
  elif [[ ${MyType%%\:*} == "LOGOUT" ]]; then
    MyRESTResponse="$(
      curl \
        --silent \
        --include \
        --connect-timeout 10 \
        --request "${MyMethod%%\:*}" "${MyMethod#*\:}" \
        --header "content-type: application/json" \
        --header "Authorization: Bearer ${MyType#*\:}" \
        | tr -d '\r'
    )"
  fi

  # Get the CURL HTTP headers isolated.
  MyRESTHeaders="$(sed '/^$/,/^$/d' <<< "${MyRESTResponse}")"

  # Remove the headers from the MyRESTResponse to get the JSON only.
  MyRESTJSON="$(sed '1,/^\s*$/d' <<< "${MyRESTResponse}")"

  # Output.
  echo "${MyRESTJSON:-${MyRESTHeaders}}"

  # If in debug mode.
  FX_ShowDebug "HEADERS:\n${MyRESTHeaders}\nRESPONSE:\n${MyRESTJSON:-EMPTY}"

  return 0
}

#########################
# Extract REST Response.
FX_RESTExtract() {
  # Expecting 1/EXTRACTKEY, 2/RESTJSON.
  local MyExtractKey="${1}"
  IFS=$'\n' MyRestJSON=( ${2} )
  local MyOutput

  # Extract information from the JSON.
  MyOutput="$(
    jq -r '
      .RESULT = (.errors // "SUCCESS :-: " + (.'"${MyExtractKey}"' | tostring))
      | .RESULT
    ' <<< "${MyRestJSON[@]}"
  )"

  # Review and return.
  [[ ${MyOutput%% :-: *} == "SUCCESS" ]] \
    && echo "${MyOutput//SUCCESS :-: /}" \
    || echo "FAILED :-: ${MyOutput:-${MyRestJSON}}"

  return 0
}

#########################
# Obtain Bearer Token.
FX_ObtainBearer() {
  local MyRESTResponse

  FX_AdvancedPrint "COMPLEX:M:-1:1:${Bold};${FWhite};${BBlue}" "BEGIN AT $(date) (${SECONDS}s)" "END"

  # REST API CALL: Obtain BEARER TOKEN for interface to MOP.
  echo $MyAccessTokenEnv
  FX_AdvancedPrint "COMPLEX:L:20:0:${Bold}" "ACCESS TOKEN"
  if [[ -n "${MyAccessTokenEnv}" ]] && ! FX_JWTDecoder "${MyAccessTokenEnv}" "VALIDATE" >/dev/null || [[ -z ${MyAccessTokenEnv} ]]; then
    # Token was available, but expired OR was not available at all.
    MyRESTResponse="$(
      FX_RESTConnect \
        "AUTH:${MyMOPClientID}:${MyMOPSecret}" \
        "POST:${MyMOPAuthURL}" \
        "grant_type=client_credentials&scope=https%3A%2F%2Fgateway.production.netfoundry.io%2F%2Fignore-scope"
    )"
    MyAccessToken="$(FX_RESTExtract "access_token" "${MyRESTResponse}")"
  else
    # Token was available, and within expiration.
    MyAccessToken="${MyAccessTokenEnv}"
  fi
  # Report and return.
  if [[ ${MyAccessToken%% :-: *} != "FAILED" ]] && FX_JWTDecoder "${MyAccessToken}" "VALIDATE"; then
    FX_AdvancedPrint "COMPLEX:L:65:0:${Normal}" "$(FX_JWTDecoder "${MyAccessToken}" "TIMEREMAINING")" "END"
  else
    FX_AdvancedPrint "COMPLEX:L:0:0:${FRed}" "FAILED [SEE OUTPUT FOLLOWING]" "END"
    echo "${MyAccessToken#* :-: }"
    return 1
  fi
}

#########################
# Obtain All Objects.
FX_ObtainObjects() {
  # Expecting 1/OBJECTTYPE.
  local MyEmbeddedList
  local MyObjectType="${1}"

  # REST API CALL: Using BEARER TOKEN, Request all available objects.
  FX_AdvancedPrint "COMPLEX:L:20:0:${Bold}" "OBTAIN ${MyObjectType^^}S"
  MyRESTResponse="$(
    FX_RESTConnect \
      "ACCESS:${MyAccessToken}" \
      "GET:${MyMOPAccessURL}/${MyObjectType}s"
  )"
  MyEmbeddedList="$(FX_RESTExtract "_embedded" "${MyRESTResponse}")"
  if [[ ${MyEmbeddedList%% :-: *} != "FAILED" ]]; then
    MyObjects="$(FX_RESTExtract "${MyObjectType}List[]" "${MyEmbeddedList}")"
    IFS=$'\n'
    MyObjectsNames=( $(FX_RESTExtract "name" "${MyObjects}") )
    MyObjectsIDs=( $(FX_RESTExtract "id" "${MyObjects}") )
    MyObjectsAttributes=( $(FX_RESTExtract "attributes" "${MyObjects}") )
    IFS=$' \t\n'
    FX_AdvancedPrint "COMPLEX:L:65:0:${Normal}" "OK! [FOUND ${#MyObjectsIDs[@]} ${MyObjectType^^} OBJECTS TOTAL]" "END"
  else
    FX_AdvancedPrint "COMPLEX:L:0:0:${FRed}" "FAILED [SEE OUTPUT FOLLOWING]" "END"
    echo "${MyEmbeddedList#* :-: }"
    return 2
  fi
}

#########################
# Update an Object.
FX_UpdateObject() {
  # Expecting 1/OBJECTTYPE, 2/ID, 3/NAME, 4/ATTRIBUTES.
  local MyObjectType="${1}"
  local MyObjectID="${2}"
  local MyObjectName="${3}"
  local MyObjectAttributes="${4}"

  # REST API CALL: Using BEARER TOKEN and Object UUID, Set the attributes of the object.
  MyRESTResponse="$(
    FX_RESTConnect \
      "ACCESS:${MyAccessToken}" \
      "PUT:${MyMOPAccessURL}/${MyObjectType}/${MyObjectID}" \
      "{
        \"attributes\": ${MyObjectAttributes},
        \"name\": \"${MyObjectName}\"
      }"
  )"
  MyObjectAttributes="$(FX_RESTExtract "attributes[] // \"EMPTY\"" "${MyRESTResponse}")"
  if [[ ${MyObjectAttributes%% :-: *} != "FAILED" ]]; then
    FX_AdvancedPrint "COMPLEX:L:0:0:${FGreen}" "OK!" "END"
  else
    FX_AdvancedPrint "COMPLEX:L:0:0:${FRed}" "FAILED [SEE OUTPUT FOLLOWING]" "END"
    echo "${MyObjectAttributes#* :-: }"
    return 3
  fi
}

#########################
# JSON Mod Add/Del Item.
FX_JSONMod() {
  # Expecting 1/TYPE, 2/ARRAYSTRING, 3/TARGET
  local MyType="${1}" MyArrStr="${2}" MyTarget="${3}"

  if [[ ${MyType} == "ADDATTR" ]]; then
    echo "${MyArrStr}" \
      | jq -c --arg TARGET "${MyTarget}" 'del(.[] | select(. == $TARGET))' \
      | jq -c --arg TARGET "${MyTarget}" '. + [$TARGET]'
  elif [[ ${MyType} == "DELATTR" ]]; then
    echo "${MyArrStr}" \
      | jq -c --arg TARGET "${MyTarget}" 'del(.[] | select(. == $TARGET))'
  fi

  return 0
}

#########################
# Runtime.
FX_Runtime() {
  #########################
  # Object Worker.
  FXSUB_ObjectWorker() {
    local ThisObjectName ThisObjectAttributes FoundSemaArr
    local i n x z
    FoundSemaArr=( "FALSE" "FALSE" ) # 0/FOUNDNAME, 1/FOUNDATTRIBUTE.
    for ((i=0;i<${#MyObjectsNames[@]};i++)); do
      ThisObjectName="${MyObjectsNames[${i}]}"
      ThisObjectAttributes="${MyObjectsAttributes[${i}]}"
      [[ "${MyMode[2]}" == "INSENSITIVE" ]] \
        && shopt -s nocasematch
      if { [[ "${MyTargetName}" == "ANY" ]]; } \
      || { [[ "${MyMode[3]}" == "SPECIFIC" ]] && [[ "${ThisObjectName}" == "${MyTargetName}" ]]; } \
      || { [[ "${MyMode[3]}" == "FUZZY" ]] && [[ "${ThisObjectName}" =~ ${MyTargetName} ]]; } \
      || { [[ "${MyMode[3]}" == "INVERTFUZZY" ]] && [[ ! "${ThisObjectName}" =~ ${MyTargetName} ]]; }; then
        FoundSemaArr=( "TRUE" "FALSE" )
        [[ "${MyTargetName}" != "ANY" ]] \
          && read -r ThisObjectName < <(echo -e "${ThisObjectName//${BASH_REMATCH}/\\e[${Underline};${FYellow}m${BASH_REMATCH}\\e[${Normal}m\\e[${FLiteBlue}m}")
        if [[ "${MyTargetAttributes}" == "ANY" ]]; then
          FoundSemaArr[1]="TRUE"
        else
          for ((z=0;z<${#MyTargetAttributes[@]};z++)); do
            # Target attribute was found (at least one).
            if [[ "${ThisObjectAttributes}" =~ "${MyTargetAttributes[${z}]}" ]]; then
              FoundSemaArr[1]="TRUE"
              read -r ThisObjectAttributes < <(echo -e "${ThisObjectAttributes//${BASH_REMATCH//\"/}/\\e[${Underline};${FYellow}m${BASH_REMATCH//\"/}\\e[${Normal}m}")
            fi
          done
        fi
        if [[ "${FoundSemaArr[0]}" == "TRUE" ]] && [[ "${FoundSemaArr[1]}" == "TRUE" ]]; then
          if [[ "${MyMode[1]}" == "REVIEW" ]]; then
            FX_AdvancedPrint \
              "FILL:1:0:${Normal}" "COMPLEX:L:5:2:${FLiteBlue}" "#$((++n))" \
              "COMPLEX:L:65:2:${FLiteBlue}" "${ThisObjectName}" \
              "COMPLEX:L:0:0:${Dimmed}" "${MyObjectsIDs[${i}]}" "NEXT" \
              "FILL:2:0:${Normal}" "COMPLEX:L:2:1:${FLiteBlue}" "┗━" "COMPLEX:L:0:0:${Normal}" "${ThisObjectAttributes}" "END"
          elif [[ "${MyMode[1]}" == "MODIFY" ]]; then
            MyObjectAttributesOLD="${MyObjectsAttributes[${i}]}"
            FX_AdvancedPrint \
              "FILL:1:0:${Normal}" "COMPLEX:L:5:2:${FLiteBlue}" "#$((++n))" \
              "COMPLEX:L:65:2:${FLiteBlue}" "${ThisObjectName}" \
              "COMPLEX:L:0:0:${Dimmed}" "${MyObjectsIDs[${i}]}" "NEXT" \
              "FILL:2:0:${Normal}" "COMPLEX:L:11:2:${FLiteBlue}" "┗┳OLD" "COMPLEX:L:0:0:${Normal}" "${MyObjectAttributesOLD}" "END"
            for ((x=0;x<${#MyModifications[@]};x++)); do
              if [[ "${MyModifications[${x}]%:*}" == "ADDATTR" ]]; then
                FX_AdvancedPrint "FILL:3:0:${Normal}" "COMPLEX:L:10:2:${FCyan}" "┣ADDATTR" "COMPLEX:L:0:0:${Normal}" "${MyModifications[${x}]#*:}" "END"
                MyObjectsAttributes[${i}]="$(FX_JSONMod "ADDATTR" "${MyObjectsAttributes[${i}]}" "${MyModifications[${x}]#*:}")"
              elif [[ "${MyModifications[${x}]%:*}" == "DELATTR" ]]; then
                FX_AdvancedPrint "FILL:3:0:${Normal}" "COMPLEX:L:10:2:${FMagenta}" "┣DELATTR" "COMPLEX:L:0:0:${Normal}" "${MyModifications[${x}]#*:}" "END"
                MyObjectsAttributes[${i}]="$(FX_JSONMod "DELATTR" "${MyObjectsAttributes[${i}]}" "${MyModifications[${x}]#*:}")"
              fi
            done
            FX_AdvancedPrint \
              "FILL:3:0:${Normal}" "COMPLEX:L:10:2:${FLiteBlue}" "┣NEW" "COMPLEX:L:0:0:${Normal}" "${MyObjectsAttributes[${i}]}" "NEXT" \
              "FILL:3:0:${Normal}" "COMPLEX:L:10:2:${FLiteBlue}" "┗STATUS"
            if [[ "${MyObjectAttributesOLD}" == "${MyObjectsAttributes[${i}]}" ]]; then
              FX_AdvancedPrint "COMPLEX:L:0:0:${FYellow}" "NO_CHANGE" "END"
            else
              FX_UpdateObject "${MyMode[0],,}s" "${MyObjectsIDs[${i}]}" "${MyObjectsNames[${i}]}" "${MyObjectsAttributes[${i}]}" || FX_GotoExit "13"
            fi
          fi
        fi
      fi
    done
    shopt -u nocasematch
    [[ "${FoundSemaArr}" == "TRUE" ]] \
      && return 0 \
      || return 1
  }

  # Expecting 1/MODE, 2/TARGETNAME(S), 3/TARGETATTRIBUTE(S), 4/MODIFICATIONS.
  local MyRESTResponse MyModifications MyTargetNames MyTargetName MyTargetAttributes
  local MyObjects MyObjectsNames MyObjectsIDs MyObjectsAttributes i
  local MyMode="${1}"
  local MyInTargetNames="${2}"
  local MyInTargetAttributes="${3}"
  local MyInModifications="${4}"

  FX_AdvancedPrint "COMPLEX:M:-1:1:${Bold};${FWhite};${BBlue}" "BEGIN RUNTIME (${SECONDS}s)" "END"

  # 0/ENDPOINT|SERVICE, 1/REVIEW|MODIFY|CREATE|REMOVE, 2/SENSITIVE|INSENSITIVE, 3/SPECIFIC|FUZZY
  IFS=',' read -ra MyMode <<< "${MyMode}"

  if [[ "${MyMode[1]}" == "MODIFY" ]]; then
    if [[ -z "${MyInModifications}" ]]; then
      FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Modification mode without any modifications." "END"
      FX_GotoExit "1"
    fi
    IFS=$'\n' read -d '\n' -ra MyModifications <<< "${MyInModifications//:::/${NL}}"
  fi

  if [[ "${MyMode[1]}" == "REVIEW" ]] || [[ "${MyMode[1]}" == "MODIFY" ]] || [[ "${MyMode[1]}" == "CREATE" ]] || [[ "${MyMode[1]}" == "REMOVE" ]]; then
    IFS=$'\n' read -d '\n' -ra MyTargetNames <<< "${MyInTargetNames//:::/${NL}}"
    IFS=$'\n' read -d '\n' -ra MyTargetAttributes <<< "${MyInTargetAttributes//:::/${NL}}"
  fi

  FX_ObtainObjects "${MyMode[0],,}" || FX_GotoExit "2"

  for ((i=0;i<${#MyTargetNames[@]};i++)); do
    MyTargetName="${MyTargetNames[${i}]}"
    FX_AdvancedPrint "COMPLEX:L:20:0:${Bold}" "${MyMode[0]} NAME SET" "COMPLEX:L:0:0:${Normal}" "${MyTargetName:-ALL TARGETS}" "END"
    FXSUB_ObjectWorker || FX_AdvancedPrint "FILL:20:0:${Normal}" "COMPLEX:L:0:0:${FYellow}" "NAME SET RETURNED NO RESULTS" "END"
  done

  return 0
}

##################################################
## MAIN                                         ##
##################################################
# Initial information output.
FX_LogoMessaging "${SystemLogo}" "${MyPurpose[0]}" "${MyPurpose[1]}"

# Switching syntax.
# Get options from command line.
	while getopts "n:N:m:a:A:ifFhH" ThisOpt; do
		case "${ThisOpt}" in
      "n")
        [[ "${#OPTARG}" -le 2 ]] \
          && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Name \"${OPTARG}\" must be greater than TWO characters long." "END" \
          && FX_GotoExit "1"
        [[ "${OPTARG}" =~ ":::" ]] \
          && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Name \"${OPTARG}\" has an illegal character \":::\"." "END" \
          && FX_GotoExit "1"
        MyTargetNames+="${OPTARG}:::"
      ;;
      "N")
        [[ "${#OPTARG}" -le 2 ]] \
          && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Attribute \"${OPTARG}\" must be greater than TWO characters long." "END" \
          && FX_GotoExit "1"
        [[ "${OPTARG}" =~ ":::" ]] \
          && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Attribute \"${OPTARG}\" has an illegal character \":::\"." "END" \
          && FX_GotoExit "1"
        MyTargetAttributes+="#${OPTARG//#/}:::"
      ;;
      "m")
        case "${OPTARG}" in
          "ENDPOINTREVIEW"|"ER")
            MyMode[1]="ENDPOINT"
            MyMode[2]="REVIEW"
          ;;
          "ENDPOINTCREATE"|"EC")
            MyMode[1]="ENDPOINT"
            MyMode[2]="CREATE"
          ;;
          "ENDPOINTMODIFY"|"EM")
            MyMode[1]="ENDPOINT"
            MyMode[2]="MODIFY"
          ;;
          "ENDPOINTDELETE"|"ED")
            MyMode[1]="ENDPOINT"
            MyMode[2]="DELETE"
          ;;
          "SERVICEREVIEW"|"SR")
            MyMode[1]="SERVICE"
            MyMode[2]="REVIEW"
          ;;
          "SERVICECREATE"|"SC")
            MyMode[1]="SERVICE"
            MyMode[2]="CREATE"
          ;;
          "SERVICEMODIFY"|"SM")
            MyMode[1]="SERVICE"
            MyMode[2]="MODIFY"
          ;;
          "SERVICEDELETE"|"SD")
            MyMode[1]="SERVICE"
            MyMode[2]="DELETE"
          ;;
          *)
            FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "INVALID MODE SPECIFIED \"${OPTARG}\"." "END"
            FX_GotoExit "1"
          ;;
        esac
      ;;
      "a")
        [[ "${#OPTARG}" -le 2 ]] \
          && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Attribute \"${OPTARG}\" must be greater than TWO characters long." "END" \
          && FX_GotoExit "1"
        [[ "${OPTARG}" =~ ":::" ]] \
          && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Attribute \"${OPTARG}\" has an illegal character \":::\"." "END" \
          && FX_GotoExit "1"
        MyModifications+="ADDATTR:#${OPTARG//#/}:::"
      ;;
      "A")
        [[ "${#OPTARG}" -le 2 ]] \
          && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Attribute \"${OPTARG}\" must be greater than TWO characters long." "END" \
          && FX_GotoExit "1"
        [[ "${OPTARG}" =~ ":::" ]] \
          && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "Attribute \"${OPTARG}\" has an illegal character \":::\"." "END" \
          && FX_GotoExit "1"
        MyModifications+="DELATTR:#${OPTARG//#/}:::"
      ;;
      "i")
        MyMode[3]="INSENSITIVE"
      ;;
      "f")
        MyMode[4]="FUZZY"
      ;;
      "F")
        MyMode[4]="INVERTFUZZY"
      ;;
      "h"|"H"|*)
        FX_PrintHelp
        FX_CheckEnvironment "HELPCONTEXT"
        FX_GotoExit "99"
      ;;
    esac
  done

  # 1/ENDPOINT|SERVICE, 2/REVIEW|MODIFY|CREATE|REMOVE, 3/SENSITIVE|INSENSITIVE, 4/SPECIFIC|FUZZY|INVERTFUZZY
  MyMode[0]="${MyMode[1]:=UNSET},${MyMode[2]:=REVIEW},${MyMode[3]:=SENSITIVE},${MyMode[4]:=SPECIFIC}"
  MyTargetNames="${MyTargetNames%:::*}" # Remove trailing comma.
  MyTargetAttributes="${MyTargetAttributes%:::*}" # Remove trailing comma.
  MyModifications="${MyModifications%:::*}" # Remove trailing comma.

  # Print runtime info.
  FX_CheckEnvironment "RUNCONTEXT" || FX_GotoExit "1"

  # Check rules and set defaults.
  [[ "${MyMode[1]:-UNSET}" == "UNSET" ]] \
    && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "MODE REQUIRED." "END" \
    && FX_GotoExit "99"
  [[ "${MyMode[2]:-UNSET}" == "MODIFY" ]] || [[ "${MyMode[2]:-UNSET}" == "CREATE" ]] || [[ "${MyMode[2]:-UNSET}" == "REMOVE" ]] && [[ -z "${MyTargetNames}" ]] \
    && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "TARGET(S) REQUIRED FOR MODE ${MyMode[1]} [MODIFY | CREATE | REMOVE]." "END" \
    && FX_GotoExit "99"
  [[ "${MyMode[2]:-UNSET}" == "MODIFY" ]] && [[ -z "${MyModifications}" ]] \
    && FX_AdvancedPrint "COMPLEX:L:20:0:${FRed}" "ERROR" "COMPLEX:L:0:0:${Normal}" "ATTRIBUTE(S) REQUIRED FOR MODE ${MyMode[1]} [MODIFY]." "END" \
    && FX_GotoExit "99"
  [[ -z "${MyTargetNames}" ]] \
    && MyTargetNames="ANY"
  [[ -z "${MyTargetAttributes}" ]] \
    && MyTargetAttributes="ANY"
  [[ -z "${MyModifications}" ]] \
    && MyModifications="ANY"

  # Print selections.
  FX_AdvancedPrint \
    "COMPLEX:L:20:0:${Bold}" "MODE" "COMPLEX:L:0:0:${Normal}" "${MyMode[1]} -> ${MyMode[2]}" "NEXT" \
    "COMPLEX:L:20:0:${Bold}" "TARGET NAME SET(S)" "COMPLEX:L:0:0:${Normal}" "${MyTargetNames//:::/ [AND] }" "NEXT" \
    "COMPLEX:L:20:0:${Bold}" "TARGET ATTRIBUTE(S)" "COMPLEX:L:0:0:${Normal}" "${MyTargetAttributes//:::/ [OR] }" "NEXT" \
    "COMPLEX:L:20:0:${Bold}" "CASE SENSITIVITY" "COMPLEX:L:0:0:${Normal}" "${MyMode[3]}" "NEXT" \
    "COMPLEX:L:20:0:${Bold}" "SELECT METHOD" "COMPLEX:L:0:0:${Normal}" "${MyMode[4]}" "NEXT" \
    "COMPLEX:L:20:0:${Bold}" "MODIFICATIONS" "COMPLEX:L:0:0:${Normal}" "${MyModifications//:::/ [AND] }" "END"

  # Obtain the BEARER TOKEN for further operations.
  FX_ObtainBearer || FX_GotoExit "$?"

  case "${MyMode[1]}" in
    "ENDPOINT"|"SERVICE")
      if [[ "${MyMode[2]}" == "MODIFY" ]] || [[ "${MyMode[2]}" == "REMOVE" ]] && [[ "${MyMode[4]}" =~ "FUZZY" ]]; then
        FX_AdvancedPrint \
          "COMPLEX:L:20:0:${FMagenta}" "WARNING" "COMPLEX:L:0:0:${Normal}" "MODIFY/REMOVE MODE with fuzzy or inverted fuzzy name select can be dangerous!" "NEXT" \
          "COMPLEX:L:20:0:${FMagenta}" "WARNING" "COMPLEX:L:0:0:${Normal}" "The following will be affected by your command." "END"
        FX_Runtime "${MyMode[1]},REVIEW,${MyMode[3]},${MyMode[4]}" "${MyTargetNames}" "${MyTargetAttributes}"
        FX_GetYorN "Proceed? " "No" "30" \
          && FX_Runtime "${MyMode[0]}" "${MyTargetNames}" "${MyTargetAttributes}" "${MyModifications}"
      else
        FX_Runtime "${MyMode[0]}" "${MyTargetNames}" "${MyTargetAttributes}" "${MyModifications}"
      fi
    ;;
  esac

FX_GotoExit "0"
####################################################################################################
# EOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOF #
####################################################################################################