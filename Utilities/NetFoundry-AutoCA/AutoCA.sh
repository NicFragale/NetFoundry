#!/bin/bash
##########################################################################################################################################
# 20241203 - NFragale@NetFoundry - Example script for root/intermediate/clientcert/enrollment functiions of a NetFoundry network.
##########################################################################################################################################

##########################################################################################################################################
# Initialize Variables (DYNAMIC)
##########################################################################################################################################
# NetFoundry Networks: The target NetFoundry network(s).
NF_NetworkIDs=(
  "a7a4a330-ae19-4d7d-8b9f-39cbd320c05f" # 0
)
# NetFoundry Networks CA Naming: Within the Xn NetFoundry networks, configure/utilize each of these CAs.
NF_CATargets=(
  "FragaleCA" # 0
)
# NetFoundry Networks CA Subject Basis: The corresponding x509 syntax for the 3rd Party CA.
CA_SubjectBasis=(
  "/C=US/ST=CO/L=Parker/O=${NF_CATargets[0]}" # 0
)
# Format of Naming: Any combination of strings and/or the these variables [caName] [caId] [commonName] [requestedName] [identityId].
NF_IdentityNamings=(
  "[caName]-[commonName]" # 0
)
# Attributes given by default in (\"#[NAME]\",) format.
NF_IdentityAttributes=(
  "\"#NetFoundry_Admin\",\"#Customer_Admin\"" # 0
)

##########################################################################################################################################
# DO NOT EDIT BELOW THIS LINE WITHOUT KNOWING WHAT YOU ARE DOING!
##########################################################################################################################################

##########################################################################################################################################
# Initialize Variables (STATIC)
##########################################################################################################################################
SECONDS="0" # Seconds counting since launched.
MYPWD="$(pwd)" # Assumes the current working directory as the basis of all operations.
NF_BaseDir="NetFoundry" # The basis of every network and the identities created for them.
NF_NetworksDir="${MYPWD}/${NF_BaseDir}/Networks"
ParentPID="$$" # The PID of this script (AKA the parent that spawns subprocesses).
MyName=( "${0##*/}" "${0}" ) # NAME (0/Base 1/Full) of the program.
FLAG_LearnMode="FALSE" # TRUE/FALSE - Flag to print extra information about commands that are run.
FLAG_SetupCA="FALSE" # TRUE/FALSE - Flag to setup CAs locally.
FLAG_ValidateCA="FALSE" # TRUE/FALSE - Flag to validate a 3rd party CA in NetFoundry.
FLAG_EnrollIDs="FALSE" # TRUE/FALSE - Flag to enroll identities agaist a validated 3rd party CA.
ZIDQuantity="1" # The default quantity of identities to create and enroll.
export Normal="0" Bold="1" Dimmed="2" Invert="7" # Trigger codes for BASH.
export FBlack="30" FRed="31" FGreen="32" FYellow="33" FBlue="34" FMagenta="35" FCyan="36" FLiteGray="37" # Foreground color codes for BASH.
export FDarkGray="90" FLiteRed="91" FLiteGreen="92" FLiteYellow="93" FLiteBlue="94" FLiteMagenta="95" FLiteCyan="96" FWhite="37" # Foreground color codes for BASH.
export BBlack="40" BRed="41" BGreen="42" BYellow="43" BBlue="44" BMagenta="45" BCyan="46" BLiteGray="47" # Background color codes for BASH.
export BDarkGray="100" BLiteRed="101" BLiteGreen="102" BLiteYellow="103" BLiteBlue="104" BLiteMagenta="105" BLiteCyan="106" BWhite="107" # Background color codes for BASH.
export ValidIP="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" # REGEX to match IPv4 addresses.
export ValidPrefix="(3[01]|[12][0-9]|[1-9])" # A REGEX string to match a valid CIDR number.
export ValidNumber="^[0-9]+$"
export AlphaArray=( {A..Z} ) # All letters in the English alphabet (A-Z).
LimitFancy="FALSE" # A flag that hold whether the program can output certain screen effects.
export LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8" TERM="xterm-256color"
for ((i=0;i<120;i++)); do
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
SystemLogo="${OEMLogo:-
    _   __       __   ______                          __
   / | / /___   / /_ / ____/____   __  __ ____   ____/ /_____ __  __
  /  |/ // _ \ / __// /_   / __ \ / / / // __ \ / __  // ___// / / /
 / /|  //  __// /_ / __/  / /_/ // /_/ // / / // /_/ // /   / /_/ /
/_/ |_/ \___/ \__//_/     \____/ \__,_//_/ /_/ \__,_//_/    \__, /
                                                           /____/
}" # Logo.

##########################################################################################################################################
# Functions
##########################################################################################################################################
#################################################################################
# Create an array of input options, randomize, and return one of them.
FX_RandomPicker() {
  # Expecting 1/InputArray.
  local InputArray=( ${1} )

  # Output a random selection from the array.
  echo ${InputArray[$((${RANDOM}%${#InputArray[@]}))]}

  return 0
}

#################################################################################
# Obtain screen info.
FX_ObtainScreenInfo() {
  # Expecting 1/MINCOLWIDTH 2/OUTPUTCONTROL[OPTIONAL].
  local MyMinColumnWidth="${1:-0}"
  local MyOutputControl="${2:-ALL}" # ALL/SCREENWIDTH/MAXCOLWIDTH/COLUMNS

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
  case ${MyOutputControl} in
    "SCREENWIDTH")
      echo "${MyScreenWidth}"
    ;;
    "MAXCOLWIDTH")
      echo "${MyMaxColumnWidth}"
    ;;
    "COLUMNS")
      echo "${TableColumns[*]}"
    ;;
    "ALL"|*)
      echo "${MyScreenWidth} ${MyMaxColumnWidth} ${TableColumns[*]}"
    ;;
  esac

  return 0
}

#################################################################################
# Colorize Output.
FX_AdvancedPrint() {
  FXSUB_ShowHelp() {
    FX_AdvancedPrint "COMPLEX:M:${MyScreenWidth}:1:${BBlue};${FWhite}" "ADVANCED PRINTING EXAMPLES" "END"

    # Show available fill patterns.
    FX_AdvancedPrint "COMPLEX:L:${MyScreenWidth}:1:${BBlue};${FWhite}" "FILL PATTERNS" "END"
    for ((i=0;i<${#PadLine[*]};i++)); do
      FX_AdvancedPrint "COMPLEX:L:10:0:${Normal}" "LINE STYLE" "COMPLEX:L:4:0:${Normal}" " ${i} " "FILL:$((MyScreenWidth-15)):${i}:${Normal}" "END"
    done

    # Show how to create a padded number.
    FX_AdvancedPrint "COMPLEX:L:${MyScreenWidth}:1:${BBlue};${FWhite}" "PADDED NUMBERS" "END"
    FX_AdvancedPrint \
      "COMPLEX:L:10:0:${Normal}" "3x0 LEFT" "COMPLEX:L:3:10:${Normal}" "1" "NEXT" \
      "COMPLEX:L:10:0:${Normal}" "8x0 LEFT" "COMPLEX:L:8:10:${Normal}" "1" "NEXT" \
      "COMPLEX:L:10:0:${Normal}" "3x0 RIGHT" "COMPLEX:R:3:10:${Normal}" "1" "NEXT" \
      "COMPLEX:L:10:0:${Normal}" "8x0 RIGHT" "COMPLEX:R:8:10:${Normal}" "1" "NEXT" \
      "END"
  }

  # SubFunction for gathering information on the position of the cursor.
  FXSUB_GetCursorPosition() {
    # Expecting NOINPUT.
    local CursorPositionInput

    # Get the cursor position and strip out decoration data.
    IFS=';' read -sdR -p $'\E[6n' CursorPositionInput[0] CursorPositionInput[1]
    CursorPositionInput[0]="${CursorPositionInput[0]#*[}"

    CursorPositionOutput=( $((${CursorPositionInput[0]}-1)) $((${CursorPositionInput[1]}-1)) )
  }

  # SubFunction for manipulating the cursor position.
  FXSUB_ManipulateCursor() {
    # Expecting 1/ACTION, 2/DirectiveA, 3/DirectiveB.
    local ThisAction="${1}" DirectiveA="${2}" DirectiveB="${3}"
    local i

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
  local PrinterArray PrinterContext
  local PrintOutSyntax PrintOutTrail DebugOut AllLines CursorPositionOutput
  local itr=0
  local IFS=$'\n\t '

  # Gather information on the screen if required.
  [[ -z ${MyScreenWidth} ]] \
    && read -d $'\n' MyScreenWidth < <(FX_ObtainScreenInfo "0" "SCREENWIDTH")

  # Invisible cursor while printing.
  FXSUB_ManipulateCursor "INVISIBLE"

  # Parse the instruction set array.
  while [[ -n ${1} ]]; do
    unset PrinterArray PrinterContext
    PrinterArray=( ${1//:/ } )
    PrinterContext="${2}"

    # Handle ignoring of output colors.
    [[ ${FLAG_IgnoreColorizer:-FALSE} == "TRUE" ]] \
      && PrinterArray[4]="${Normal}"

    # Handle request for full width.
    [[ "${PrinterArray[2]}" -lt 0 ]] \
      && PrinterArray[2]="${MyScreenWidth}"

    # Element Xn TYPE.
    case "${PrinterArray[0]}" in
      # PrinterArray array structure is "0/TYPE:1/BOUNDARIES:2/PADNUM:3/COLOR".
      "FILL")
        # Expecting elements.
        if [[ ${PrinterArray[1]:=NULLERROR} == "NULLERROR" ]] \
          || [[ ${PrinterArray[2]:=NULLERROR} == "NULLERROR" ]] \
          || [[ ${PrinterArray[3]:=NULLERROR} == "NULLERROR" ]]; then
          # Handle debug mode.
          [[ ${DebugMode} == "TRUE" ]] \
            && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}:${PrinterArray[2]}:${PrinterArray[3]}:${PrinterContext}"
          break
        fi

        # Build the current syntax.
        PrintOutSyntax="${PrintOutSyntax}\e[${PrinterArray[3]}m%s${PadLine[${PrinterArray[2]}]:0:$((${PrinterArray[1]}))}\e[1;${Normal}m"
        PrintOutTrail[itr++]=""
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
          # Handle debug mode.
          [[ ${DebugMode} == "TRUE" ]] \
            && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}:${PrinterArray[2]}:${PrinterArray[3]}:${PrinterArray[4]}:${PrinterContext}"
          break
        fi

        # Process element Xn.
        case "${PrinterArray[2]}" in
          "0")
            # No end boundary, print everything.
            PrintOutSyntax="${PrintOutSyntax}\e[${PrinterArray[4]}m%s\e[1;${Normal}m"
            PrintOutTrail[itr]="${PrinterContext}"
          ;;
          *)
            # End boundary specified.
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
          ;;
        esac
        ((itr++))
        shift 2
      ;;

      # PrinterArray array structure is "0/TYPE:1/LINES:2/COLS".
      "MOVETO"|"MOVEABSOLUTE")
        # Expecting elements.
        if [[ ${PrinterArray[1]:=NULLERROR} == "NULLERROR" ]] \
          && [[ ${PrinterArray[2]:=NULLERROR} == "NULLERROR" ]]; then
          # Handle debug mode.
          [[ ${DebugMode} == "TRUE" ]] \
            && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}:${PrinterArray[2]}"
          break
        fi

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
          # Handle debug mode.
          [[ ${DebugMode} == "TRUE" ]] \
            && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}"
          break
        fi

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
          # Handle debug mode.
          [[ ${DebugMode} == "TRUE" ]] \
            && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}"
          break
        fi

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
      "SAVEPOS"|"RESTOREPOS")
        # Expecting elements.
        [[ ${DebugMode} == "TRUE" ]] \
          && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}"

        # Flush the current queue before beginning.
        if [[ ${PrintOutSyntax} != "" ]] || [[ ${#PrintOutTrail[@]} -ne 0 ]]; then
          printf "${PrintOutSyntax}" "${PrintOutTrail[@]}"
          unset PrintOutSyntax PrintOutTrail
        fi

        FXSUB_ManipulateCursor "${PrinterArray[0]}"
        shift 1
      ;;

      # PrinterArray array structure is "0/TYPE".
      "HELP")
        # Expecting elements.
        [[ ${DebugMode} == "TRUE" ]] \
          && DebugOut="${DebugOut}/${PrinterArray[0]}:${PrinterArray[1]}"

        # Flush the current queue before beginning.
        if [[ ${PrintOutSyntax} != "" ]] || [[ ${#PrintOutTrail[@]} -ne 0 ]]; then
          printf "${PrintOutSyntax}" "${PrintOutTrail[@]}"
          unset PrintOutSyntax PrintOutTrail
        fi

        FXSUB_ShowHelp
        shift 1
      ;;

      # PrinterArray array structure is "0/TYPE".
      "NEXT"|"END"|*)
        # Handle debug mode.
        [[ ${DebugMode} == "TRUE" ]] \
          && DebugOut="${DebugOut}/${PrinterArray[0]}"
        if [[ ${PrinterArray[0]} == "NEXT" ]]; then
          PrintOutSyntax="${PrintOutSyntax}\n"
          ((itr++))
          shift 1
        elif [[ ${PrinterArray[0]} == "END" ]]; then
          PrintOutSyntax="${PrintOutSyntax}\n"
          break
        else
          PrintOutSyntax="${PrintOutSyntax}%s"
          PrintOutTrail[itr]="${PrinterArray[0]}"
          ((itr++))
          shift 1
        fi
      ;;
    esac
  done

  # Handle debug mode.
  [[ ${FLAG_DebugMode:-FALSE} == "TRUE" ]] \
    && logger -t "${MyName}" "${FUNCNAME[1]}/${DebugOut}"

  # Request a print of the gathered syntax and context.
  printf "${PrintOutSyntax}" "${PrintOutTrail[@]}"

  # Make cursor visible again.
  FXSUB_ManipulateCursor "VISIBLE"

  return 0
}

#################################################################################
# Print Helper.
FX_PrintHelper() {
  # Expecting 1/FILLINFO, 2/ECHOSTDOUTBOOL, */COMMAND.
  local MyFillInfo="${1}"
  local MyEchoStdOut="${2}"
  local MyCommand="${@:3}"
  local MyCommandOutput MyCommandCounter="0"

  [[ ${FLAG_LearnMode} == "TRUE" ]] \
    && FX_AdvancedPrint \
      "${MyFillInfo}" "COMPLEX:L:0:0:${FYellow}" "[COMMAND]" "NEXT" \
      "${MyFillInfo}" "COMPLEX:L:0:0:${Normal}" "${MyCommand}" "END" >&2

  bash -c "${MyCommand}" 2>&1 | while IFS= read -r MyCommandOutput || [[ -n "${MyCommandOutput}" ]]; do
    [[ ${FLAG_LearnMode} == "TRUE" ]] && [[ $((MyCommandCounter++)) -eq "0" ]] \
      && FX_AdvancedPrint "${MyFillInfo}" "COMPLEX:L:0:0:${FYellow}" "[OUTPUT]" "END" >&2
    [[ ${FLAG_LearnMode} == "TRUE" ]] \
      && FX_AdvancedPrint "${MyFillInfo}" "COMPLEX:L:0:0:${Dimmed}" "${MyCommandOutput}" "END" >&2
    [[ ${MyEchoStdOut} == "TRUE" ]] \
      && echo "${MyCommandOutput}"
  done
}

#################################################################################
# Logo Printer.
FX_LogoMessaging() {
  # Expecting 1/ThisLogo, 2/MessageA, 3/MessageB, 4/MessageC.
  local ThisLogo="${1}" ThisMessageA="${2}" ThisMessageB="${3}" ThisMessageC="${4}"

  # Check if able to run.
  [[ ${FLAG_RUN_LogoMessaging:-TRUE} != "TRUE" ]] \
    && return 1

  # Ensure the logo lines are congruent, then print.
  while IFS=$'\n' read -r EachLine; do
    [[ ${#EachLine} -gt ${MaxLogoLine} ]] \
      && MaxLogoLine="${#EachLine}"
    [[ ${#EachLine} -ne 0 ]] && [[ ${#EachLine} -lt ${MinLogoLine} ]] \
      && MinLogoLine="${#EachLine}"
  done < <(printf '%s\n' "${ThisLogo}")
  ThisColor="$(FX_RandomPicker "${BWhite};${FBlack} ${FRed} ${FGreen} ${FYellow} ${FBlue} ${FMagenta} ${FCyan} ${FLiteGray}")"

  # Gather information on the screen.
  local MyScreenWidth MyMinColumnWidth MyMaxColumnWidth TableColumns
  local MaxLine=0 ActiveLine=0 ActiveColumn=0
  MyMinColumnWidth="30"
  read -d $'\n' MyScreenWidth MyMaxColumnWidth TableColumns < <(FX_ObtainScreenInfo "${MyMinColumnWidth}")
  TableColumns=( ${TableColumns} )

  while IFS=$'\n' read -r EachLine; do
    FX_AdvancedPrint \
      "COMPLEX:M:${MyScreenWidth}:0:${Bold};${ThisColor}" \
      "$(printf "%-${MaxLogoLine}s" "${EachLine}")" \
      "NEXT"
  done < <(printf "%s" "${ThisLogo}")

  # Print login messaging after screen clearing.
  FX_AdvancedPrint \
    "COMPLEX:M:${MyScreenWidth}:0:${Normal}" "${ThisMessageA}" \
    "NEXT" \
    "COMPLEX:M:${MyScreenWidth}:0:${Normal}" "${ThisMessageB}" \
    "NEXT" \
    "COMPLEX:M:${MyScreenWidth}:0:${Normal}" "${ThisMessageC}" \
    "NEXT" \
    "END"

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

#################################################################################
# Primary Runtime Function.
FX_Primary() {
  # Expecting 1/NetworkID, 2/CATarget.
  local NF_NetworkID="${1}"
  local NF_CATarget="${2}"
  local CA_Intermediate CA_IntermediateDir

  FX_AdvancedPrint "COMPLEX:L:-1:2:${FBlue};${Bold}" "VALIDATION: NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: BEGIN [$((SECONDS/60))m $((SECONDS%60))s]" "END"

  FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Creating directories." "END"
  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" mkdir -vp ${NF_NetworksDir}/${NF_NetworkID}/${NF_CATarget}/{certs,csr,private,identities}

  CA_Intermediate="CA_Intermediate_${NF_CATarget}"
  CA_IntermediateDir="${MYPWD}/${NF_BaseDir}/${CA_Intermediate}"

  FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Formatting certificate for upload to NetFoundry." "END"
  CA_SigningCert="$(FX_PrintHelper "FILL:2:0:${Normal}" "TRUE" openssl x509 -in ${CA_IntermediateDir}/${CA_Intermediate}.crt -outform PEM)"
  CA_SigningCert="${CA_SigningCert//$'\n'/\\n}"

  NF_MOPJSON="$(\
    FX_PrintHelper "FILL:2:0:${Normal}" "TRUE" curl \"https://gateway.production.netfoundry.io/core/v2/certificate-authorities\" \
        -s \
        -X \"POST\" \
        -H \"Content-Type: application/json\" \
        -H \"Accept: application/json\" \
        -H \"Authorization: Bearer ${NF_BearerToken}\" \
        --data-binary \'{ \
          \"selected\":false, \
          \"authEnabled\":true, \
          \"endpointAttributes\":[${NF_IdentityAttributes}], \
          \"networkId\":\"${NF_NetworkID}\", \
          \"name\":\"${NF_CATarget}\", \
          \"certPem\":\"${CA_SigningCert}\", \
          \"autoCaEnrollmentEnabled\":true, \
          \"identityNameFormat\":\"${NF_IdentityNamings}\" \
        }\'
  )"

  read -d '' -r NF_CAID NF_CAValidateToken NF_NetworkJWT < <( \
    jq -r '
      .id,.verificationToken,.jwt
    ' <<< "${NF_MOPJSON}"
  )

  if [[ ! -f "${NF_NetworksDir}/${NF_NetworkID}/${NF_CAID}.conf" ]]; then
    FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Saving validation information." "END"
cat << EOFEOFEOF > ${NF_NetworksDir}/${NF_NetworkID}/${NF_CAID}.conf
export NF_NetworkID="${NF_NetworkID}"
export NF_CAID="${NF_CAID}"
export NF_CAValidateToken="${NF_CAValidateToken}"
export NF_NetworkJWT="${NF_NetworkJWT}"
EOFEOFEOF
  fi

  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" cat ${NF_NetworksDir}/${NF_NetworkID}/${NF_CAID}.conf

  FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Saving network JWT." "END"
  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" tee ${NF_NetworksDir}/${NF_NetworkID}/${NF_NetworkID}.jwt < <(echo "${NF_NetworkJWT}")

  FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Generating private key." "END"
  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl genrsa -out ${MYPWD}/${NF_BaseDir}/${CA_Intermediate}/private/${NF_NetworkID}-NFVALIDATE.key 2048

  FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Generating CSR with private key." "END"
  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl req -new -key ${MYPWD}/${NF_BaseDir}/${CA_Intermediate}/private/${NF_NetworkID}-NFVALIDATE.key -out ${MYPWD}/${NF_BaseDir}/${CA_Intermediate}/csr/${NF_NetworkID}-NFVALIDATE.csr -subj "${CA_SubjectBasis}/OU=${NF_NetworkID}/CN=${NF_CAValidateToken}"

  FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Generating signed certificate from CSR with [${CA_Intermediate}] private key." "END"
  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl ca -config ${MYPWD}/${NF_BaseDir}/${CA_Intermediate}/${CA_Intermediate}.conf -in ${MYPWD}/${NF_BaseDir}/${CA_Intermediate}/csr/${NF_NetworkID}-NFVALIDATE.csr -out ${MYPWD}/${NF_BaseDir}/${CA_Intermediate}/certs/${NF_NetworkID}-NFVALIDATE.crt -batch
  CA_ValidatedClientCert="$(FX_PrintHelper "FILL:2:0:${Normal}" "TRUE" openssl x509 -in ${MYPWD}/${NF_BaseDir}/${CA_Intermediate}/certs/${NF_NetworkID}-NFVALIDATE.crt -outform PEM)"

  NF_MOPJSON="$(\
    FX_PrintHelper "FILL:2:0:${Normal}" "TRUE" curl \"https://gateway.production.netfoundry.io/core/v2/certificate-authorities/${NF_CAID}/verify\" \
      -s \
      -X \"POST\" \
      -H \"Content-Type: text/plain\" \
      -H \"Accept: application/json\" \
      -H \"Authorization: Bearer ${NF_BearerToken}\" \
      --data-binary \""${CA_ValidatedClientCert}"\"
  )"

  FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Generating configuration file \"${NF_NetworksDir}/${NF_NetworkID}/${NF_CATarget}.conf\"." "END"
  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" tee ${NF_NetworksDir}/${NF_NetworkID}/${NF_CATarget}.conf < <(sed "/new_certs_dir/s|=.*|= ${NF_NetworksDir}/${NF_NetworkID}/${NF_CATarget}/certs|" ${CA_IntermediateDir}/${CA_Intermediate}.conf)
}

FX_Secondary() {
    # Expecting 1/NetworkID, 2/CATarget, 3/ZIDQuantity.
    local NF_NetworkID="${1}"
    local NF_CATarget="${2}"
    local NF_ZIDQuantity="${3}"
    local NF_ZIDDir

    NF_ZIDDir="${NF_NetworksDir}/${NF_NetworkID}"
    source ${NF_ZIDDir}/*.conf

    #################################################################################
    # Client Certificate Creation (Looping)
    # NOTE: The following assumes you have the ZITI CLI
    #       or access to an Edge Tunnel with enrollment functionality.
    FX_AdvancedPrint "COMPLEX:L:-1:2:${FBlue};${Bold}" "CLIENT CERTIFICATE CREATION: NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: BEGIN [$((SECONDS/60))m $((SECONDS%60))s]" "END"
    for ((i=1;i<=${NF_ZIDQuantity};i++)); do
      NF_ZIDName="IDENTITY_${i}"

      # Bug!
      [[ ! -f "${NF_ZIDDir}/${NF_NetworkID}.jwt" ]] \
        && echo "${NF_NetworkJWT}" > ${NF_ZIDDir}/${NF_NetworkID}.jwt

      FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Generating private key for \"${NF_ZIDName}\"." "END"
      FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl genrsa -out ${NF_ZIDDir}/${NF_CATarget}/private/${NF_ZIDName}.key 2048

      FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Generating CSR with private key for \"${NF_ZIDName}\"." "END"
      FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl req -new -key ${NF_ZIDDir}/${NF_CATarget}/private/${NF_ZIDName}.key -out ${NF_ZIDDir}/${NF_CATarget}/csr/${NF_ZIDName}.csr -subj "${CA_SubjectBasis}/OU=${NF_CATarget}/CN=${NF_ZIDName}"

      FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Generating signed certificate from CSR with [${NF_CATarget}] private key for \"${NF_ZIDName}\"." "END"
      FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl ca -config ${NF_ZIDDir}/${NF_CATarget}.conf -in ${NF_ZIDDir}/${NF_CATarget}/csr/${NF_ZIDName}.csr -out ${NF_ZIDDir}/${NF_CATarget}/certs/${NF_ZIDName}.crt -batch

      FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "NETWORK ID [${NF_NetworkID}]: CATARGET [${NF_CATarget}]: Enrolling into network for \"${NF_ZIDName}\"." "END"
      FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" ./ziti edge enroll --cert ${NF_ZIDDir}/${NF_CATarget}/certs/${NF_ZIDName}.crt --key ${NF_ZIDDir}/${NF_CATarget}/private/${NF_ZIDName}.key --jwt ${NF_ZIDDir}/${NF_NetworkID}.jwt --out ${NF_ZIDDir}/${NF_CATarget}/identities/${NF_ZIDName}.json
    done
  }

FX_SetupCAs() {
  # Expecting NO INPUT.
  local CA_Root CA_RootDir CA_Intermediate CA_IntermediateDir
  local MyTempFile
  local EachIntermediateCA

  FX_AdvancedPrint "COMPLEX:L:-1:2:${FBlue};${Bold}" "ROOT CA: BEGIN [$((SECONDS/60))m $((SECONDS%60))s]" "END"
  CA_Root="CA_Root" # ROOT CA (VERY PRIVATE) - SHOULD NOT BE ABLE TO SIGN CLIENT CERTIFICATES - IDEALLY ONLY ONE.
  CA_RootDir="${MYPWD}/${NF_BaseDir}/${CA_Root}"
  FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "ROOT CA [${CA_Root}]: Creating directories." "END"
  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" mkdir -vp ${MYPWD}/${NF_BaseDir}
  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" mkdir -vp ${CA_RootDir}/{certs,csr,private}

  #################################################################################
  # Root CA Setup
  #################################################################################
  FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "ROOT CA [${CA_Root}]: Generating private key." "END"
  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl genrsa -out ${CA_RootDir}/private/${CA_Root}.key 4096
  ## -x509: Generate a self-signed certificate.
  ## -days 3650: Valid for 10 years.
  FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "ROOT CA [${CA_Root}]: Generating self signed certificate with private key." "END"
  FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl req -x509 -new -nodes -key ${CA_RootDir}/private/${CA_Root}.key -sha256 -days 3650 -out ${CA_RootDir}/certs/${CA_Root}.crt -subj \"${CA_SubjectBasis}/OU=${CA_Root}/CN=Root\"

  #################################################################################
  # Intermediate CA(s) Setup
  #################################################################################
  FX_AdvancedPrint "COMPLEX:L:-1:2:${FBlue};${Bold}" "INTERMEDIATE CA(s): BEGIN [$((SECONDS/60))m $((SECONDS%60))s]" "END"
  for EachIntermediateCA in ${NF_CATargets[@]}; do
    CA_Intermediate="CA_Intermediate_${EachIntermediateCA}"
    CA_IntermediateDir="${MYPWD}/${NF_BaseDir}/${CA_Intermediate}"

    FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "INTERMEDIATE CA [${CA_Intermediate}]: Creating directories." "END"
    FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" mkdir -vp ${CA_IntermediateDir}/{certs,csr,private}
    FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" touch ${CA_IntermediateDir}/index.txt
    FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" tee ${CA_IntermediateDir}/serial < <(echo 1000)

    FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "INTERMEDIATE CA [${CA_Intermediate}]: Generating private key." "END"
    FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl genrsa -out ${CA_IntermediateDir}/private/${CA_Intermediate}.key 4096
    FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "INTERMEDIATE CA [${CA_Intermediate}]: Generating CSR with private key." "END"
    FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl req -new -key ${CA_IntermediateDir}/private/${CA_Intermediate}.key -out ${CA_IntermediateDir}/csr/${CA_Intermediate}.csr -subj "${CA_SubjectBasis}/OU=${CA_Intermediate}/CN=Intermediate"

    FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "INTERMEDIATE CA [${CA_Intermediate}]: Generating signed certificate from CSR with [${CA_Root}] private key." "END"
    ## -CA XXX.crt: Use the root CA certificate.
    ## -CAkey XXX.key: Use the root CA’s private key.
    ## -CAcreateserial: Generate a serial number for the intermediate certificate.
    ## basicConstraints=CA:TRUE,pathlen:0: Indicates this is a CA certificate with no additional sub-CAs allowed.
    local MyTempFile="$(mktemp)"
    echo "basicConstraints=CA:TRUE,pathlen:0" > "${MyTempFile}"
    FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" openssl x509 -req -in ${CA_IntermediateDir}/csr/${CA_Intermediate}.csr -CA ${CA_RootDir}/certs/${CA_Root}.crt -CAkey ${CA_RootDir}/private/${CA_Root}.key -CAcreateserial -out ${CA_IntermediateDir}/${CA_Intermediate}.crt -days 1825 -sha256 -extfile ${MyTempFile}
    rm -f "${MyTempFile}"

    FX_AdvancedPrint "FILL:1:0:${Normal}" "COMPLEX:L:0:0:${FGreen}" "INTERMEDIATE CA [${CA_Intermediate}]: Generating configuration file \"${CA_IntermediateDir}/${CA_Intermediate}.conf\"." "END"
cat << EOFEOFEOF > ${CA_IntermediateDir}/${CA_Intermediate}.conf
[ ca ]
default_ca = CA_default
[ CA_default ]
dir               = ${CA_IntermediateDir}
database          = ${CA_IntermediateDir}/index.txt
certificate       = ${CA_IntermediateDir}/${CA_Intermediate}.crt
private_key       = ${CA_IntermediateDir}/private/${CA_Intermediate}.key
serial            = ${CA_IntermediateDir}/serial
new_certs_dir     = ${CA_IntermediateDir}/certs
default_days      = 375
default_md        = sha256
policy            = policy_strict
[ policy_strict ]
commonName          = supplied
stateOrProvinceName = optional
countryName         = optional
emailAddress        = optional
[ req ]
distinguished_name = req_distinguished_name
x509_extensions    = v3_ca
[ v3_ca ]
basicConstraints = CA:TRUE, pathlen:0
EOFEOFEOF
    FX_PrintHelper "FILL:2:0:${Normal}" "FALSE" cat ${CA_IntermediateDir}/${CA_Intermediate}.conf
  done
}

##########################################################################################################################################
# MAIN LOOP
##########################################################################################################################################
# Init.
[[ -n ${NF_BearerToken} ]] \
  && NF_BearerTokenStatus="$(FX_JWTDecoder "${NF_BearerToken}" "TIMEREMAINING")" \
  || NF_BearerTokenStatus="CURRENTLY_NOT_SET"

# Welcome.
FX_LogoMessaging "${SystemLogo}" \
  "3rd Party CA Automation to Provision, Validate, Utilize" \
  "https://support.netfoundry.io/hc/en-us/articles/360048210572-How-to-Register-Endpoints-with-Certificates-from-Another-Authority" \
  "Environment Variable [NF_BearerToken]: ${NF_BearerTokenStatus}"

# Get options from command line.
while getopts "CVLE:" ThisOpt 2>/dev/null; do
  case ${ThisOpt} in
    "C")
      FLAG_SetupCA="TRUE"
    ;;
    "V")
      FLAG_ValidateCA="TRUE"
    ;;
    "E")
      FLAG_EnrollIDs="TRUE"
      NF_ZIDQuantity="${OPTARG:-NO_QUANTITY}"
    ;;
    "L")
      FLAG_LearnMode="TRUE"
    ;;
    *)
      FX_AdvancedPrint \
        "COMPLEX:M:-1:1:${BBlue};${Bold}" "HELP MENU" "NEXT" \
        "COMPLEX:R:10:0:${Normal}" "${MyName[0]}" "COMPLEX:L:10:0:${Normal}" " -C" "COMPLEX:L:0:0:${Normal}" "INCLUDE WORKFLOW: Create local Certificate Authorities (ROOT/INTERMEDIATE)." "NEXT" \
        "COMPLEX:R:10:0:${Normal}" "${MyName[0]}" "COMPLEX:L:10:0:${Normal}" " -V" "COMPLEX:L:0:0:${Normal}" "INCLUDE WORKFLOW: Per-Network, Upload/Validate/Enable INTERMEDIATE Certificate Authorities in NetFoundry. " "NEXT" \
        "COMPLEX:R:10:0:${Normal}" "${MyName[0]}" "COMPLEX:L:10:0:${Normal}" " -E [#]" "COMPLEX:L:0:0:${Normal}" "INCLUDE WORKFLOW: Per-Network, Create/Enroll/OutputJSON [#n] Identities using validated INTERMEDIATE Certificate Authority." "NEXT" \
        "COMPLEX:R:10:0:${Normal}" "${MyName[0]}" "COMPLEX:L:10:0:${Normal}" " -L" "COMPLEX:L:0:0:${Normal}" "LEARN MODE: Output commands used during runtime." "NEXT" \
        "COMPLEX:R:10:0:${Normal}" "${MyName[0]}" "COMPLEX:L:10:0:${Normal}" " " "COMPLEX:L:0:0:${FYellow}" "INFO: OPTIONS [-V] and [-E] required ENVIRONMENT VARIABLE \"NF_BearerToken\" to be set. (${NF_BearerTokenStatus})" "NEXT" \
        "END"
      FLAG_SetupCA="FALSE"
      FLAG_ValidateCA="FALSE"
      FLAG_EnrollIDs="FALSE"
    ;;
  esac
done

# Input checking.
if [[ ${FLAG_EnrollIDs} == "TRUE" ]]; then
  if [[ ! ${NF_ZIDQuantity} =~ ${ValidNumber} ]] || [[ ! ${NF_ZIDQuantity} -gt 0 ]]; then
    FX_AdvancedPrint "COMPLEX:M:0:1:${BRed};${Bold}" "ERROR: Value for creation/enrollment of identities \"${NF_ZIDQuantity}\" is invalid." "END"
    FLAG_SetupCA="FALSE"
    FLAG_ValidateCA="FALSE"
    FLAG_EnrollIDs="FALSE"
  fi
fi

# If required, setup the CAs first.
if [[ ${FLAG_SetupCA} == "TRUE" ]]; then
  FX_AdvancedPrint "COMPLEX:M:-1:1:${BBlue};${Bold}" "SETUP OF CERTIFICATE AUTHORITIES" "END"
  FX_SetupCAs
fi

# Validate 3rd party CAs into NetFoundry and/or enroll identities utilizing validated 3rd party CAs.
if [[ ${FLAG_ValidateCA} == "TRUE" ]] || [[ ${FLAG_EnrollIDs} == "TRUE" ]]; then
  if [[ -z "${NF_BearerToken}" ]]; then
    FX_AdvancedPrint "COMPLEX:M:0:1:${BRed};${Bold}" "ERROR: Function requires ENVIRONMENT VARIABLE \"NF_BearerToken\" to be set." "END"
  elif ! FX_JWTDecoder "${NF_BearerToken}" "VALIDATE"; then
    FX_AdvancedPrint "COMPLEX:M:0:1:${BRed};${Bold}" "ERROR: ENVIRONMENT VARIABLE \"NF_BearerToken\" is set, however, it is not valid/expired. (${NF_BearerTokenStatus})" "END"
  else
    if [[ ${FLAG_ValidateCA} == "TRUE" ]]; then
      FX_AdvancedPrint "COMPLEX:M:-1:1:${BBlue};${Bold}" "VALIDATION OF CERTIFICATE AUTHORITIES IN NETFOUNDRY" "END"
      for EachNetworkID in ${NF_NetworkIDs[@]}; do
        for EachCATarget in ${NF_CATargets[@]}; do
            FX_Primary "${EachNetworkID}" "${EachCATarget}"
        done
      done
    fi
    if [[ ${FLAG_EnrollIDs} == "TRUE" ]]; then
      FX_AdvancedPrint "COMPLEX:M:-1:1:${BBlue};${Bold}" "CREATION AND ENROLLMENT OF IDENTITIES" "END"
      for EachNetworkID in ${NF_NetworkIDs[@]}; do
        for EachCATarget in ${NF_CATargets[@]}; do
          FX_Secondary "${EachNetworkID}" "${EachCATarget}" "${NF_ZIDQuantity}"
        done
      done
    fi
  fi
fi

FX_AdvancedPrint "COMPLEX:M:-1:1:${BBlue};${Bold}" "DONE [RunTime: $((SECONDS/60))m $((SECONDS%60))s]"
tput cnorm # Ensure cursor is visible.
stty sane 2>/dev/null # Return sanity to the input processing.
exit 0
##########################################################################################################################################
# EOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOF
##########################################################################################################################################