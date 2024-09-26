#!/usr/bin/env bash
####################################################################################################
# 20240901 - Written by Nic Fragale @ NetFoundry.
MyName="customish.sh"
MyPurpose="BASH Login and Environment Conditioner."
MyWarranty="This program comes without any warranty, implied or otherwise."
MyLicense="This program has no license."
MyVersion="1.20240901"
####################################################################################################

##################################################
## ITS A TRAP!                                  ##
##################################################
trap 'COLUMNS=$(COLUMNS= tput cols)' SIGWINCH

##################################################
## DYNAMIC VARIABLES                            ##
##################################################
OEMHome="/etc/OEM_Helpers" # For OEM specific usages.
[[ -f "${OEMHome}/Branding_Update.vars" ]] \
    && source "${OEMHome}/Branding_Update.vars" # For OEM specific variables.

##################################################
## STATIC VARIABLES                             ##
##################################################
SECONDS=0 # Begins the counter for run time.
PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" # Ensures minimal paths are available.
ValidIP="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" # REGEX.
ValidPrefix="(3[01]|[12][0-9]|[1-9])" # REGEX.
Normal="0" Bold="1" Dimmed="2" Invert="7" # Trigger codes for BASH.
FBlack="30" FRed="31" FGreen="32" FYellow="33" FBlue="34" FMagenta="35" FCyan="36" FLiteGray="37" # Foreground color codes for BASH.
FDarkGray="90" FLiteRed="91" FLiteGreen="92" FLiteYellow="93" FLiteBlue="94" FLiteMagenta="95" FLiteCyan="96" FWhite="37" # Foreground color codes for BASH.
BBlack="40" BRed="41" BGreen="42" BYellow="43" BBlue="44" BMagenta="45" BCyan="46" BLiteGray="47" # Background color codes for BASH.
BDarkGray="100" BLiteRed="101" BLiteGreen="102" BLiteYellow="103" BLiteBlue="104" BLiteMagenta="105" BLiteCyan="106" BWhite="107" # Background color codes for BASH.
for ((i=0;i<60;i++)); do
    PadLine[0]+='     '
    PadLine[1]+='━━━━━'
    PadLine[2]+='·····'
    PadLine[3]+='┄┄┄┄┄'
    PadLine[4]+='╭╮╰╯'
    PadLine[5]+='╰╯╭╮'
    PadLine[6]+='╰╮╭╯'
    PadLine[7]+='╭╯╰╮'
    PadLine[8]+='┬┴┬┴'
    PadLine[9]+='▒▒▒▒'
    PadLine[10]+='0000'
done # Pad Line generation.
SystemLogo="${OEMLogo:-
    _   __     __  ______                      __
   / | / /__  / /_/ ____/___  __  ______  ____/ /______  __
  /  |/ / _ \/ __/ /_  / __ \/ / / / __ \/ __  / ___/ / / /
 / /|  /  __/ /_/ __/ / /_/ / /_/ / / / / /_/ / /  / /_/ /
/_/ |_/\___/\__/_/    \____/\__,_/_/ /_/\__,_/_/   \__, /
                                                  /____/

}" # Logo.
DefaultNomen=(
    "nicfragale@gmail.com" # 0/Email.
    "nf" # 1/Initials.
    "ziggy" # 2/Username.
    "ziti" # 3/BaseSoftwareAlias.
    "router" # 4/BaseSoftwareRouterFunction.
    "tunnel" # 5/BaseSoftwareTunnelFunction.
    "cli" # 6/BaseSoftwareCLIFunction
    "Development-Server" # 7/BaseSoftwareRouterFullName.
    "NetFoundry" # 8/Vendor.
) # Nomenclature.
SystemNomen=(
    "${OEMNomen[0]:-${DefaultNomen[0]}}"
    "${OEMNomen[1]:-${DefaultNomen[1]}}"
    "${OEMNomen[2]:-${DefaultNomen[2]}}"
    "${OEMNomen[3]:-${DefaultNomen[3]}}"
    "${OEMNomen[4]:-${DefaultNomen[4]}}"
    "${OEMNomen[5]:-${DefaultNomen[5]}}"
    "${OEMNomen[6]:-${DefaultNomen[6]}}"
    "${OEMNomen[7]:-${DefaultNomen[7]}}"
    "${OEMNomen[8]:-${DefaultNomen[8]}}"
) # Nomenclature.
SystemSupport="${SystemNomen[0]}" # Support email.
SystemLoginMessaging=(
    "HELLO - System Directive is \"${SystemNomen[8]} ${SystemNomen[7]}\"."
    "For support, please contact \"${SystemSupport}\"."
) # Login messaging.

##################################################
## FUNCTIONS                                    ##
##################################################
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
# Test input is number.
FX_TestNumber() {
    # Expecting 1/TestValue.
    local TestValue="${1}"

    # Test the value for numeric quality.
    case "${TestValue}" in
        ''|*[!0-9]*) return 1;;
        *) return 0;;
    esac
}

#########################
# Test array for element.
FX_ArraySearch() {
    # Expecting 1/SearchFor.
    local ArrayValue SearchFor="${1}"

    # Review each element of the array sent in.
    shift
    for ArrayValue; do
        # If matching, return immediately as true.
        [[ "${ArrayValue}" == "${SearchFor}" ]] \
            && return 0
    done

  # No match.
  return 1
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
# Obtain screen info.
function FX_ObtainScreenInfo() {
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

#########################
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
                        PrintOutTrail[itr]="${PrinterContext}"
                    ;;
                    *)
                        # End boundary specified.
                        if [[ ${#PrinterContext} -gt ${PrinterArray[2]} ]]; then
                            # No end boundary, print everything.
                            PrintOutSyntax="${PrintOutSyntax}\e[${PrinterArray[4]}m%s\e[1;${Normal}m"
                            PrintOutTrail[itr]="${PrinterContext}"
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

#########################
# User Access Review.
FX_UserAccessReview() {
    # Expecting 1/QuanMonths.
    local QuanMonths="${1}"
    local FlagFailed MonthItr SearchForYear SearchForMonth AllSearchResults SearchResultsIndex SearchForMonthShort SearchForMonthLong SearchResultsQuan SearchResultsInfo
    local Quan_IPs Quan_IPs_Users Quan_UserAtIPs Quan_Users RunningTotal ThisElement AllElements ThisDate i
    local CurrentDate=( $(date +"%-m") $(date +"%-Y") )
    local AllMonths=( "January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December" )

    # Check if able to run.
    [[ ${FLAG_RUN_UserAccessReview:-TRUE} != "TRUE" ]] \
        && return 1

    # Gather information on the screen.
    local MyScreenWidth MyMinColumnWidth MyMaxColumnWidth TableColumns
    local MaxLine=0 ActiveLine=0 ActiveColumn=0
    MyMinColumnWidth="60"
    read -d $'\n' MyScreenWidth MyMaxColumnWidth TableColumns < <(FX_ObtainScreenInfo "${MyMinColumnWidth}")
    TableColumns=( ${TableColumns} )

    # Produce a twelve month numeric string starting at the current month a going in reverse OR switch to failed attempts.
    case "${QuanMonths}" in
        ''|*[!0-9]*)
            QuanMonths="1"
            SearchThrough="${CurrentDate[0]}"
            FlagFailed="TRUE"
            FlagHeader="FAILED\u2000LOGINS\u2000CURRENT\u2000MONTH"
        ;;
        *)
            FlagFailed="FALSE"
            FlagHeader="SUCCESSFUL\u2000LOGINS\u2000CURRENT\u2000MONTH\u2000AND\u2000PREVIOUS\u2000[$((${QuanMonths}-1))]\u2000MONTHS"
            [[ $((${QuanMonths}-${CurrentDate[0]})) -le 0 ]] \
                && SearchThrough="$((1+(${CurrentDate[0]}-${QuanMonths})))" \
                || SearchThrough="-$(((${QuanMonths}-${CurrentDate[0]})-1))"
        ;;
    esac

    for EachMonth in $(eval echo {${CurrentDate[0]}..${SearchThrough}}); do
        # Normalize the number into a base of 12.
        SearchForYear="$(( (EachMonth - 11) / 12 + CurrentDate[1] ))"
        EachMonth="$((${EachMonth}%12))"

        # Create the substrings to search within.
        SearchForMonthLong="${AllMonths[$((${EachMonth}-1))]}"
        SearchForMonthShort="${SearchForMonthLong::3}"

        # Review the results looking for the search terms.
        if [[ ${FlagFailed:-FALSE} == "TRUE" ]]; then
            local ${SearchForMonthLong}_${SearchForYear}="$(
                awk '
                    BEGIN {
                        PROCINFO["sorted_in"]="@val_num_asc"
                    } {
                        gsub("user  from","user NULL from")
                        PARSEDLINE=gensub(/.*Invalid user (.*) from (.*) port.*/,"\\1 \\2","1")
                        split(PARSEDLINE,PARSEDARRAY)
                        USERS_IPS[PARSEDARRAY[1]"@"PARSEDARRAY[2]]++
                        USERS[PARSEDARRAY[1]]++
                        IPS[PARSEDARRAY[2]]++
                    } END {
                        for (EACH in USERS_IPS)
                            printf "%s,%s ",USERS_IPS[EACH],EACH
                        printf ": "
                        for (EACH in USERS)
                            printf "%s,%s ",USERS[EACH],EACH
                        printf ": "
                        for (EACH in IPS)
                            printf "%s,%s ",IPS[EACH],EACH
                    }
                ' < <(sudo zgrep -E '^'"${SearchForMonthLong}"'.*sshd.*Invalid' '/var/log/auth.log')
            )"
        else
            local ${SearchForMonthLong}_${SearchForYear}="$(
                awk '
                    BEGIN {
                        PROCINFO["sorted_in"]="@val_num_asc"
                    } !/shutdown/ && !/reboot/ && !/btmp/ && !/wtmp/ && !/^$/ {
                        if (/'"${SearchForMonthShort}"'.*'"${SearchForYear}"'/) {
                            USERS_IPS[$1"@"$NF]++
                            USERS[$1]++
                            IPS[$NF]++
                        }
                    } END {
                        for (EACH in USERS_IPS)
                            printf "%s,%s ",USERS_IPS[EACH],EACH
                        printf ": "
                        for (EACH in USERS)
                            printf "%s,%s ",USERS[EACH],EACH
                        printf ": "
                        for (EACH in IPS)
                            printf "%s,%s ",IPS[EACH],EACH
                    }
                ' < <(sudo last -Fia)
            )"
        fi

        # Recompile the master array of arrays.
        AllSearchResults=( "${AllSearchResults[@]}" ''"${SearchForMonthLong}_${SearchForYear}"'[@]' )
    done

    # Index the array of arrays.
    SearchResultsIndex=( 'AllSearchResults[@]' )

    FX_AdvancedPrint $(
        echo -e "COMPLEX:M:${MyScreenWidth}:1:${FBlack};${BGreen}" "${FlagHeader}"
        echo "NEXT"

        for EachArrayL1 in "${SearchResultsIndex[@]}"; do
            for EachArrayL2 in "${!EachArrayL1}"; do
                ThisDate="${EachArrayL2/\[@\]/}"
                MoveToColumn="${TableColumns[$((${ActiveColumn}%${#TableColumns[@]}))]}"
                ((MonthItr+=1))

                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:M:1:0:${FBlue}" "┏"
                echo -e "COMPLEX:M:$((${MyMaxColumnWidth}-1)):0:${Bold};${BBlue}" "${ThisDate%_*}\u2000${ThisDate#*_}\u2000[${MonthItr}/${QuanMonths}]"
                echo "NEXT"
                ((ActiveLine=2))

                for AllElements in "${!EachArrayL2}"; do
                    Quan_UserAtIPs=( ${AllElements%%:*} )
                    Quan_IPs_Users="${AllElements#*:}"
                    Quan_IPs=( ${Quan_IPs_Users#*:} )
                    Quan_Users=( ${Quan_IPs_Users%:*} )

                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:L:2:0:${FBlue}" "┣┳"
                    echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-2)):0:${FLiteRed}" "UNIQUE\u2000USERs\u2000@IPs"
                    echo "NEXT"
                    ((RunningTotal=0))
                    ((ActiveLine+=1))

                    if [[ ${#Quan_UserAtIPs[@]} -gt 0 ]]; then
                        for ((i=0;i<${#Quan_UserAtIPs[@]};i++)); do
                            ThisElement=( ${Quan_UserAtIPs[${i}]//,/ } )
                            echo "MOVETO:0:${MoveToColumn}"
                            [[ ${i} -lt $((${#Quan_UserAtIPs[@]}-1)) ]] \
                                && echo "COMPLEX:R:3:0:${FBlue}" "┃┣━" \
                                || echo "COMPLEX:R:3:0:${FBlue}" "┃┗━"
                            echo "COMPLEX:L:5:2:${Normal}" "${ThisElement[0]}"
                            echo "COMPLEX:L:$((${MyMaxColumnWidth}-8)):0:${Normal}" "${ThisElement[1]}"
                            echo "NEXT"
                            ((ActiveLine+=1))
                            ((RunningTotal+=${ThisElement[0]}))
                        done
                    else
                        echo "MOVETO:0:${MoveToColumn}"
                        echo "COMPLEX:R:3:0:${FBlue}" "┃┗━"
                        echo "COMPLEX:L:$((${MyMaxColumnWidth}-3)):0:${Normal}" "0"
                        echo "NEXT"
                        ((ActiveLine+=1))
                    fi

                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:R:2:0:${FBlue}" "┣┳"
                    echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-2)):0:${FLiteRed}" "UNIQUE\u2000IPs"
                    echo "NEXT"
                    ((ActiveLine+=1))

                    if [[ ${#Quan_IPs[@]} -gt 0 ]]; then
                        for ((i=0;i<${#Quan_IPs[@]};i++)); do
                            ThisElement=( ${Quan_IPs[${i}]//,/ } )
                            echo "MOVETO:0:${MoveToColumn}"
                            [[ ${i} -lt $((${#Quan_IPs[@]}-1)) ]] \
                                && echo "COMPLEX:L:3:0:${FBlue}" "┃┣━" \
                                || echo "COMPLEX:L:3:0:${FBlue}" "┃┗━"
                            echo "COMPLEX:L:5:2:${Normal}" "${ThisElement[0]}"
                            echo "COMPLEX:L:$((${MyMaxColumnWidth}-8)):0:${Normal}" "${ThisElement[1]}"
                            echo "NEXT"
                            ((ActiveLine+=1))
                        done
                    else
                        echo "MOVETO:0:${MoveToColumn}"
                        echo "COMPLEX:L:3:0:${FBlue}" "┃┗━"
                        echo "COMPLEX:L:$((${MyMaxColumnWidth}-3)):0:${Normal}" "0"
                        echo "NEXT"
                        ((ActiveLine+=1))
                    fi

                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:L:2:0:${FBlue}" "┣┳"
                    echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-2)):0:${FLiteRed}" "UNIQUE\u2000USERs"
                    echo "NEXT"
                    ((ActiveLine+=1))

                    if [[ ${#Quan_Users[@]} -gt 0 ]]; then
                        for ((i=0;i<${#Quan_Users[@]};i++)); do
                            ThisElement=( ${Quan_Users[${i}]//,/ } )
                            echo "MOVETO:0:${MoveToColumn}"
                            [[ ${i} -lt $((${#Quan_Users[@]}-1)) ]] \
                                && echo "COMPLEX:L:3:0:${FBlue}" "┃┣━" \
                                || echo "COMPLEX:L:3:0:${FBlue}" "┃┗━"
                            echo "COMPLEX:L:5:2:${Normal}" "${ThisElement[0]}"
                            echo "COMPLEX:L:$((${MyMaxColumnWidth}-8)):0:${Normal}" "${ThisElement[1]}"
                            echo "NEXT"
                            ((ActiveLine+=1))
                        done
                    else
                        echo "MOVETO:0:${MoveToColumn}"
                        echo "COMPLEX:L:3:0:${FBlue}" "┃┗━"
                        echo "COMPLEX:L:$((${MyMaxColumnWidth}-3)):0:${Normal}" "0"
                        echo "NEXT"
                        ((ActiveLine+=1))
                    fi

                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:L:2:0:${FBlue}" "┗┳"
                    echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-2)):0:${FRed}" "UNIQUE\u2000TOTAL"
                    echo "NEXT"
                    ((ActiveLine+=1))

                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:R:3:0:${FBlue}" " ┗━"
                    echo "COMPLEX:L:$((${MyMaxColumnWidth}-3)):0:${Normal}" "${RunningTotal}"
                    echo "NEXT"
                    ((ActiveLine+=1))

                    [[ ${ActiveLine} -gt ${MaxLine} ]] \
                        && ((MaxLine=${ActiveLine}))
                    if [[ ${MonthItr} -ge ${QuanMonths} ]] || [[ $(((${ActiveColumn}+1)%${#TableColumns[@]})) -eq 0 ]]; then
                        [[ ${MaxLine} -gt ${ActiveLine} ]] \
                            && echo "MOVETO:$((${MaxLine}-${ActiveLine})):0"
                        [[ $(((${ActiveColumn}+1)%${#TableColumns[@]})) -eq 0 ]] \
                            && ((MaxLine=0))
                    else
                        echo "MOVETO:-${ActiveLine}:0"
                    fi
                done

                echo "NEXT"
                ((ActiveColumn+=1))
            done
        done
    )

    return 0
}

#########################
# IP Info Init.
FX_IPInfo() {
    # SubFunction for gathering info on the local IP.
    FXSUB_GetIP() {
        # Expecting 1/ThisDevice.
        local ThisDevice="${1}"
        local ThisIP

        # Retrieve the IP address locally associated to this device.
        ThisIP="$(
            ip addr show dev "${ThisDevice}" 2>/dev/null \
            | awk '
                BEGIN {
                    IPADDR="UNKNOWN"
                } {
                    for (i=1;i<=NF;i++) {
                        if ($i~/'"${ValidIP}"'\//) {
                            gsub("/.*","")
                            IPADDR=$i
                        }
                    }
                } END {
                    print IPADDR
                }
            '
        )"

        echo -e "${ThisIP}"
        return 0
    }

    # SubFunction for gathering info on the local network.
    FXSUB_GetNetwork() {
        # Expecting 1/ThisDevice.
        local ThisDevice="${1}"

        # Retrieve the default IP and network associated to this device.
        read -d $'\n' ThisDefault ThisNetwork < <(
            ip route show dev "${ThisDevice}" \
            | awk '
                BEGIN {
                    DEFAULT="UNKNOWN";NETWORK="UNKNOWN"
                } {
                    for (i=1;i<=NF;i++) {
                        if ($i~/'"${ValidIP}"'\//) {
                            NETWORK=$i
                        } else if ($i~/default/ && $(i+1)~/via/) {
                            if ($(i+2)~/'"${ValidIP}"'/) {
                                DEFAULT=$(i+2)
                            }
                        }
                    }
                } END {
                    print DEFAULT,NETWORK
                }
            ' 2>/dev/null
        )

        echo -e "${ThisDefault}"
        echo -e "${ThisNetwork}"
        return 0
    }

    # SubFunction for gathering info on a public IP.
    FXSUB_GetPublicInfo() {
        # Expecting 1/ThisDevice 2/ThisDefault.
        local ThisDevice="${1}" ThisDefault="${2}"

        # Rerieve the public IP and details of it associated to this device.
        [[ ${ThisDefault} != "UNKNOWN" ]] \
            && read -d $'\n' -r ThisCountry ThisRegion ThisCity ThisOrg ThisPubIP < <(
                (
                    curl -o- --fail --silent --connect-timeout 5 --interface "${ThisDevice}" http://ip-api.com \
                    || curl -o- --fail --silent --connect-timeout 5 --interface "${ThisDevice}" https://ipinfo.io
                ) \
                | awk -F: '
                    BEGIN {
                        COUNTRY="COUNTRY?";REGION="REGION?";CITY="CITY?";ORG="ORG?";PUBIP="PUBIP?"
                    } {
                        gsub(/\x1b\[[0-9;]*m/,"",$2)
                        gsub(/^[ \t]+/,"",$2)
                        gsub(/[ \t]+$/,"",$2)
                        gsub(/"/,"",$2)
                        gsub(/,$/,"",$2)
                        gsub(/ /,"\\u2000",$2)
                        if(/"ip"/||/\"query\"/)PUBIP=$2
                        if(/"country"/)COUNTRY=$2
                        if(/"region"/)REGION=$2
                        if(/"city"/)CITY=$2
                        if(/"org"/)ORG=$2
                    } END {
                        print COUNTRY,REGION,CITY,ORG,PUBIP
                    }
                ' 2>/dev/null
            )

        echo -e "${ThisPubIP}"
        echo -e "${ThisOrg}"
        echo -e "${ThisRegion}"
        echo -e "${ThisCity}"
        echo -e "${ThisCountry}"
        return 0
    }

    # Expecting [NO_INPUT].
    local MyDefault ThisDefault EachDevice BGPIDS i DeviceItr ReturnArray

    # Check if able to run.
    [[ ${FLAG_RUN_IPInfo:-TRUE} != "TRUE" ]] \
        && return 1

    # Gather information on the screen.
    local MyScreenWidth MyMinColumnWidth MyMaxColumnWidth TableColumns
    local MaxLine=0 ActiveLine=0 ActiveColumn=0
    MyMinColumnWidth="60"
    read -d $'\n' MyScreenWidth MyMaxColumnWidth TableColumns < <(FX_ObtainScreenInfo "${MyMinColumnWidth}")
    TableColumns=( ${TableColumns} )

    # One global value to assess is the default route.
    MyDefault="$(
        ip route get 1.1.1.1 \
        | awk '
            BEGIN {
                DEFAULT="NONE/UNKNOWN"
            } {
                for (i=1;i<=NF;i++) {
                    if ($i=="via") {
                        if ($(i+1)~/'"${ValidIP}"'/) {
                            DEFAULT=$(i+1)
                        }
                    }
                }
            } END {
                print DEFAULT
            }
        ' 2>/dev/null
    )"

    [[ ${FLAG_LimitLoginInfo:-FALSE} == "FALSE" ]] \
        && DeviceSearch="/state UP/||/state DOWN/||/state UNKNOWN/" \
        || DeviceSearch="/state UP/||/state DOWN/"

    AllDevices=( $(ip addr show | awk -F: ''"${DeviceSearch}"'{print $2}' || echo NO_DEVICES_DETECTED) )

    FX_AdvancedPrint $(
        echo -e "COMPLEX:M:${MyScreenWidth}:1:${FBlack};${BGreen}" "SYSTEM\u2000DEVICE\u2000INFORMATION"
        echo "NEXT"

        for ((i=0;i<${#AllDevices[@]};i++)); do

            [[ ${AllDevices[${i}]} == "lo" ]] \
                && continue

            MoveToColumn="${TableColumns[$((${ActiveColumn}%${#TableColumns[@]}))]}"

            echo "MOVETO:0:${MoveToColumn}"
            echo "COMPLEX:M:1:0:${FBlue}" "┏"
            echo -e "COMPLEX:M:$((${MyMaxColumnWidth}-1)):0:${Bold};${BBlue}" "${AllDevices[${i}]}"
            echo "NEXT"
            ((ActiveLine=2))

            echo "MOVETO:0:${MoveToColumn}"
            ReturnArray='' ReturnArray=( $(FXSUB_GetIP ${AllDevices[${i}]}) )
            if [[ ${ReturnArray[0]} != "UNKNOWN" ]]; then
                echo "COMPLEX:L:2:0:${FBlue}" "┣┳"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-2)):0:${FLiteRed}" "LAN\u2000INFO"
                echo "NEXT"
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:L:3:0:${FBlue}" "┃┣━"
                echo "COMPLEX:L:10:2:${Normal}" "IP"
                echo "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${ReturnArray[0]}"
                echo "NEXT"
                ReturnArray='' ReturnArray=( $(FXSUB_GetNetwork ${AllDevices[${i}]}) )
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:L:3:0:${FBlue}" "┃┣━"
                echo "COMPLEX:L:10:2:${Normal}" "GW"
                ThisDefault="${ReturnArray[0]}"
                [[ ${ThisDefault} == "${MyDefault}" ]] \
                    && echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${FGreen}" "${ThisDefault//${MyDefault}/${MyDefault}\\u2000[PRIMARY]}" \
                    || echo "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${ThisDefault}"
                echo "NEXT"
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:L:3:0:${FBlue}" "┃┗━"
                echo "COMPLEX:L:10:2:${Normal}" "NET"
                echo "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${ReturnArray[1]}"
                echo "NEXT"
                ((ActiveLine+=4))

                if [[ ${ThisDefault} != "UNKNOWN" ]]; then
                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:L:2:0:${FBlue}" "┗┳"
                    echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-2)):0:${FLiteRed}" "WAN\u2000INFO"
                    echo "NEXT"
                    ReturnArray='' ReturnArray=( $(FXSUB_GetPublicInfo ${AllDevices[${i}]}) )
                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:R:3:0:${FBlue}" " ┣━"
                    echo "COMPLEX:L:10:2:${Normal}" "IP"
                    echo "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${ReturnArray[0]}"
                    echo "NEXT"
                    echo "MOVETO:0:${MoveToColumn}"
                    if [[ ${#ReturnArray[1]} -gt $((${MyMaxColumnWidth}-13)) ]]; then
                        echo "COMPLEX:R:3:0:${FBlue}" " ┣┳"
                        echo "COMPLEX:L:10:2:${Normal}" "ORG"
                        echo "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${ReturnArray[1]:0:$((${MyMaxColumnWidth}-13))}"
                        echo "NEXT"
                        echo "MOVETO:0:${MoveToColumn}"
                        echo "COMPLEX:R:3:0:${FBlue}" " ┃┗"
                        echo "FILL:10:2:${Normal}"
                        echo "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${ReturnArray[1]:$((${MyMaxColumnWidth}-13))}"
                        echo "NEXT"
                        ((ActiveLine+=1))
                    else
                        echo "COMPLEX:R:3:0:${FBlue}" " ┣━"
                        echo "COMPLEX:L:10:2:${Normal}" "ORG"
                        echo "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${ReturnArray[1]:0:$((${MyMaxColumnWidth}-13))}"
                        echo "NEXT"
                    fi
                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:R:3:0:${FBlue}" " ┣━"
                    echo "COMPLEX:L:10:2:${Normal}" "REGION"
                    echo "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${ReturnArray[2]}"
                    echo "NEXT"
                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:R:3:0:${FBlue}" " ┣━"
                    echo "COMPLEX:L:10:2:${Normal}" "CITY"
                    echo "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${ReturnArray[3]}"
                    echo "NEXT"
                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:R:3:0:${FBlue}" " ┗━"
                    echo "COMPLEX:L:10:2:${Normal}" "COUNTRY"
                    echo "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${ReturnArray[4]}"
                    echo "NEXT"
                    ((ActiveLine+=6))
                else
                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:L:2:0:${FBlue}" "┗━"
                    echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-2)):0:${FRed}" "NO\u2000WAN\u2000INFO"
                    echo "NEXT"
                    ((ActiveLine+=1))
                fi
            else
                # The analysis returned no IP address for this device.
                echo "COMPLEX:L:2:0:${FBlue}" "┗━"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-2)):0:${FRed}" "NO\u2000LAN\u2000INFO"
                echo "NEXT"
                ((ActiveLine+=1))
            fi

            [[ ${ActiveLine} -ge ${MaxLine} ]] \
                && ((MaxLine=${ActiveLine}))
            if [[ $((${i}+1)) -eq ${#AllDevices[@]} ]] || [[ $(((${ActiveColumn}+1)%${#TableColumns[@]})) -eq 0 ]]; then
                [[ ${MaxLine} -gt ${ActiveLine} ]] \
                    && echo "MOVETO:$((${MaxLine}-${ActiveLine})):0"
                [[ $(((${ActiveColumn}+1)%${#TableColumns[@]})) -eq 0 ]] \
                    && ((MaxLine=0))
            else
                echo "MOVETO:-${ActiveLine}:0"
            fi

            echo "NEXT"
            ((ActiveColumn+=1))

        done
    )

    return 0
}

#########################
# Pre-Login Checking.
FX_PreLoginCheck() {
    # Expecting [NO_INPUT].

    # If the UID is ROOT/0.
    if [[ $EUID -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

#########################
# Obtain TCP Sock Ages.
FX_SocketInfo() {
    # Expecting [NO_INPUT]
    local i AllSockets EachSocket SocketINODE SocketIPPort SocketDetails SocketAge SocketPID SocketApp SocketTime
    local ProcessedSocketNames ProcessedSocketsByPID PrintSocketNames PrintSocketPID PrintAllSocketsTotal PrintAllSocketDetails PrintEachSocketDetails

    # Check if able to run.
    [[ ${FLAG_RUN_SocketInfo:-TRUE} != "TRUE" ]] \
        && return 1

    # Gather information on the screen.
    local MyScreenWidth MyMinColumnWidth MyMaxColumnWidth TableColumns
    local MaxLine=0 ActiveLine=0 ActiveColumn=0
    MyMinColumnWidth="60"
    read -d $'\n' MyScreenWidth MyMaxColumnWidth TableColumns < <(FX_ObtainScreenInfo "${MyMinColumnWidth}")
    TableColumns=( ${TableColumns} )

    # Get all sockets (TCP) in the system which have a valid destination IP, port, and INODE.
    AllSockets=$(sudo awk '!/local_address/&&$3!="00000000:0000"&&$10!="0"{print $3"_"$10}' /proc/net/tcp 2>/dev/null)

    # Analysis of all active sockets reported by the kernel.
    for EachSocket in ${AllSockets}; do
        # Turn the line into an array, EX (#0/0281250A:CA0C #1/351634).
        EachSocket=( ${EachSocket//_/ } )
        # The INODE is the second part of the array.
        SocketINODE=${EachSocket[1]}

        # Convert the HEX version of the socket into a real IP:Port. (Note: HEX values come in reverse.)
        SocketIPPort=$(printf "%d.%d.%d.%d:%d\n" "0x${EachSocket[0]:6:2}" "0x${EachSocket[0]:4:2}" "0x${EachSocket[0]:2:2}" "0x${EachSocket[0]:0:2}" "0x${EachSocket[0]:9:4}")

        declare -A ProcessedSocketNames ProcessedSocketsByPID

        # Using the inode, we can find the PID in the file system and the modification timestamp of that inode. (FILENAME TIME.MTIME)
        AllSocketDetails=( $(sudo find /proc/*/fd -lname "socket:\[${SocketINODE}\]" -printf "%p_%T@\n" 2>/dev/null) )
        # Parse each SocketDetail for information.
        for ((i=0;i<${#AllSocketDetails[@]};i++)); do
            EachSocketDetail=( ${AllSocketDetails[${i}]//_/ } )
            SocketPID=( ${EachSocketDetail[0]//\// } )
            SocketApp="$(sudo cat /proc/${SocketPID[1]}/comm 2>/dev/null)"

            # Place into the presorted array.
            SocketAge[0]="$(($(date +%s) - ${EachSocketDetail[1]%%\.*}))"
            SocketAge[1]="$((SocketAge[0] / 86400))" # Days.
            SocketAge[2]="$((SocketAge[0] % 86400 / 3600))" # Hours.
            SocketAge[3]="$((SocketAge[0] % 86400 % 3600 / 60))" # Minutes.
            SocketAge[4]="$((SocketAge[0] % 86400 % 3600 % 60))" # Seconds.

            # Listing of all unique applications / PIDs running.
            if [[ ! ${ProcessedSocketNames[${SocketApp}]} ]]; then
                # This application was not found at all - add to the name:pid tracker and counter.
                ProcessedSocketNames[${SocketApp}]+="${SocketApp}:${SocketPID[1]} "
                ((ProcessedSocketNames[COUNTER]+=1))
            elif [[ ${ProcessedSocketNames[${SocketApp}]} ]] && [[ ! ${ProcessedSocketsByPID[${SocketApp}:${SocketPID[1]}]} ]]; then
                # This application was found, but the name:pid was not - add to the name:pid tracker.
                ProcessedSocketNames[${SocketApp}]+="${SocketApp}:${SocketPID[1]} "
            fi

            # Add to the detail tracker.
            # 1/AppName, 2/AppPID, 3/IP:PORT, 4/Age_EpochSeconds, 5/Age_Days, 6/Age_Hours, 7/Age_Minutes, 8/Age_Seconds
            ProcessedSocketsByPID[${SocketApp}:${SocketPID[1]}]+="${SocketApp}:${SocketPID[1]}:${SocketIPPort}:${SocketAge[0]}:${SocketAge[1]}:${SocketAge[2]}:${SocketAge[3]}:${SocketAge[4]} "
        done
    done

    # Parse and print.
    FX_AdvancedPrint $(

        echo -e "COMPLEX:M:${MyScreenWidth}:1:${FBlack};${BGreen}" "SYSTEM\u2000SOCKET\u2000INFORMATION"
        echo "NEXT"

        # Socket names are used for columns.
        for PrintSocketNames in "${!ProcessedSocketNames[@]}"; do
            # Counter is skipped.
            [[ ${PrintSocketNames} == "COUNTER" ]] \
                && continue
            PrintAllSocketsTotal=0

            # Obtain what column should be used for printing.
            MoveToColumn="${TableColumns[$((${ActiveColumn}%${#TableColumns[@]}))]}"

            # Move to the active column location.
            echo "MOVETO:0:${MoveToColumn}"
            echo "COMPLEX:M:1:0:${FBlue}" "┏"
            echo "COMPLEX:M:$((${MyMaxColumnWidth}-1)):0:${Bold};${BBlue}" "${PrintSocketNames}"
            echo "NEXT"
            ((ActiveLine=2))

            # PIDs are used for sublevel.
            for PrintSocketPID in ${ProcessedSocketNames[${PrintSocketNames}]}; do

                # Sort by the age of the socket.
                PrintAllSocketDetails=( $(FX_ArraySort ":" "5" ${ProcessedSocketsByPID[${PrintSocketPID}]}) )
                ((PrintAllSocketsTotal+=${#PrintAllSocketDetails[@]}))
                # Sort by the age of the socket.
                if [[ ${#PrintAllSocketDetails[@]} -gt 1 ]]; then
                    PrintTiers=( "┃┣━" "┃┗━" )
                else
                    PrintTiers=( "┃┗┳" "┃┗━" )
                fi

                # Print the detail associated with each socket specific to the PID therein.
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:R:2:0:${FBlue}" "┣┳"
                echo "COMPLEX:L:10:2:${FLiteRed}" "PID"
                echo "COMPLEX:L:$((${MyMaxColumnWidth}-12)):0:${FLiteRed}" "${PrintSocketPID#*:}"
                echo "NEXT"
                ((ActiveLine+=1))
                for ((i=0;i<${#PrintAllSocketDetails[@]};i++)); do
                    PrintEachSocketDetails=( ${PrintAllSocketDetails[${i}]//:/ } )
                    echo "MOVETO:0:${MoveToColumn}"
                    [[ $((${i}+1)) -lt ${#PrintAllSocketDetails[@]} ]] \
                        && echo -e "COMPLEX:L:3:0:${FBlue}" "${PrintTiers[0]}" \
                        || echo -e "COMPLEX:L:3:0:${FBlue}" "${PrintTiers[1]}"
                    echo "COMPLEX:L:10:2:${Normal}" "Socket"
                    echo "COMPLEX:L:23:0:${Normal}" "${PrintEachSocketDetails[2]}:${PrintEachSocketDetails[3]}"
                    echo "COMPLEX:R:1:0:${Normal}" "["
                    echo "COMPLEX:R:4:0:${FYellow}" "${PrintEachSocketDetails[5]}d "
                    echo "COMPLEX:R:4:0:${FYellow}" "${PrintEachSocketDetails[6]}h "
                    echo "COMPLEX:R:4:0:${FYellow}" "${PrintEachSocketDetails[7]}m "
                    echo "COMPLEX:R:4:0:${FYellow}" "${PrintEachSocketDetails[8]}s "
                    echo "COMPLEX:R:1:0:${Normal}" "]"
                    echo "NEXT"
                    ((ActiveLine+=1))
                done

            done

            echo "MOVETO:0:${MoveToColumn}"
            echo "COMPLEX:R:2:0:${FBlue}" "┗━"
            echo "COMPLEX:L:10:2:${FRed}" "TOTAL"
            echo "COMPLEX:L:$((${MyMaxColumnWidth}-12)):0:${FRed}" "${PrintAllSocketsTotal}"
            echo "NEXT"
            ((ActiveLine+=1))

            # Cursor location assessment.
            [[ ${ActiveLine} -gt ${MaxLine} ]] \
                && ((MaxLine=${ActiveLine}))
            if ! ((--ProcessedSocketNames[COUNTER])) || [[ $(((${ActiveColumn}+1)%${#TableColumns[@]})) -eq 0 ]]; then
                [[ ${MaxLine} -gt ${ActiveLine} ]] \
                    && echo "MOVETO:$((${MaxLine}-${ActiveLine})):0"
                [[ $(((${ActiveColumn}+1)%${#TableColumns[@]})) -eq 0 ]] \
                    && ((MaxLine=0))
            else
                echo "MOVETO:-${ActiveLine}:0"
            fi

            # Next socket.
            echo "NEXT"
            ((ActiveColumn+=1))

        done
    )

    return 0
}

#########################
# Condition Environment.
FX_EnvCondition() {
    # Expecting 1/, .
    return 0
}

#########################
# Software Checking.
FX_SoftwareCheck() {
    # SubFunction for gathering run state from systemctl.
    FXSUB_GetRunState() {
        # Expecting 1/TargetSoftware.
        local TargetSoftware="${1}"
        local ReturnCode ReturnInfo ParsedInfo

        ReturnInfo="$(systemctl status "${TargetSoftware}" --lines=0 --no-pager 2>&1)"
        ReturnCode="$?"
        ParsedInfo[0]="$(awk '
            /Main PID:/ {
                printf "%s",$3
            }
        ' <<<"${ReturnInfo}")"
        ParsedInfo[1]="$(awk -F';' '
            /Active:/ {
                gsub(/ /,"\\u2000",$2)
                printf "[Since%s]",$2
            }
        ' <<<"${ReturnInfo}")"

        case "${ReturnCode}" in
            0) echo "RUNNING:${ParsedInfo[0]:-UNKNOWN_PID}\u2000${ParsedInfo[1]:-UNKNOWN_RUNTIME}";;
            1) echo "DEAD_PID";;
            2) echo "DEAD_LOCKED";;
            3) echo "STOPPED";;
            4|*) echo "ERROR";;
        esac

        return 0
    }
    # SubFunction for gathering registration state of identities.
    FXSUB_GetRegistrationState() {
        # Expecting 1/TargetIdLocation, 2/TargetFileType.
        local TargetIdLocation="${1}" TargetFileType="${2}"
        local i EpochTime ReturnInfo ParsedInfo

        EpochTime="$(date +%s)"
        ReturnInfoArray=( $(find "${TargetIdLocation}" -name "*.${TargetFileType}" -type f -maxdepth 1 -printf "%f:%.10T@ " 2>/dev/null || echo "UNREGISTERED") )
        if [[ ${ReturnInfoArray[0]} == "UNREGISTERED" ]]; then
            echo "UNREGISTERED"
        else
            for ((i=0;i<${#ReturnInfoArray[@]};i++)); do
                echo -n "${ReturnInfoArray[${i}]%:*}:$(((${EpochTime}-${ReturnInfoArray[${i}]#*:})/86400))d "
            done
        fi

        return 0
    }

    # Expecting 1/SoftwareType.
    local SoftwareType="${1}"
    local i StandardPath StandardSoftwareBinaries StandardSoftwarePaths StandardSoftwareRunStates AllSoftwareInfo

    # Check if able to run.
    [[ ${FLAG_RUN_SoftwareCheck:-TRUE} != "TRUE" ]] \
        && return 1

    # Gather information on the screen.
    local MyScreenWidth MyMinColumnWidth MyMaxColumnWidth TableColumns
    local MaxLine=0 ActiveLine=0 ActiveColumn=0
    MyMinColumnWidth="60"
    read -d $'\n' MyScreenWidth MyMaxColumnWidth TableColumns < <(FX_ObtainScreenInfo "${MyMinColumnWidth}")
    TableColumns=( ${TableColumns} )

    # Compile an array of the standard software packages.
    declare -A AllSoftwareInfo
    StandardPath="/opt/${DefaultNomen[8],,}/${DefaultNomen[3]}"
    StandardSoftwareBinaries=(
        "${DefaultNomen[3]}" # 0/ZITI CLI.
        "${DefaultNomen[3]}-${DefaultNomen[4]}" # 1/ZITI-ROUTER.
        "${DefaultNomen[3]}-${DefaultNomen[5]}" # 2/ZITI-TUNNEL.
        "${DefaultNomen[3]}-edge-${DefaultNomen[5]}" # 3/ZITI-EDGE-TUNNEL.
    )
    StandardSoftwarePaths=(
        "${StandardPath}"
        "${StandardPath}/${DefaultNomen[3]}-${DefaultNomen[4]}"
        "${StandardPath}/${DefaultNomen[3]}-${DefaultNomen[5]}"
        "${StandardPath}/${DefaultNomen[3]}-edge-${DefaultNomen[5]}"
    )
    StandardSoftwareRunStates=(
        "ON-DEMAND"
        "$(FXSUB_GetRunState ${StandardSoftwareBinaries[1]})"
        "$(FXSUB_GetRunState ${StandardSoftwareBinaries[2]})"
        "$(FXSUB_GetRunState ${StandardSoftwareBinaries[3]})"
    )
    StandardSoftwareRegistrationIndicator=(
        "UNAVAILABLE"
        "yml"
        "jwt"
        "jwt"
    )
    StandardSoftwareRegisteredName=(
        "UNAVAILABLE"
        "$(awk 'gsub(/ /,"\\u2000")' "/opt/${DefaultNomen[8],,}/.name" 2>/dev/null || echo "UNAVAILABLE")"
        "UNAVAILABLE"
        "UNAVAILABLE"
    )

    for ((i=0;i<${#StandardSoftwareBinaries[@]};i++)); do
        if [[ -x "${StandardSoftwarePaths[${i}]}/${StandardSoftwareBinaries[${i}]}" ]]; then
            ((AllSoftwareInfo[INSTALLEDCOUNTER]+=1))
            AllSoftwareInfo[INSTALLEDNAMES]+="${StandardSoftwareBinaries[${i}]} "
            AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} INSTALLSTATE]="INSTALLED"
            AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} PATH]="${StandardSoftwarePaths[${i}]}"
            AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} RUNSTATE]="${StandardSoftwareRunStates[${i}]:-UNAVAILABLE}"
            AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTRATIONINFO]="$(FXSUB_GetRegistrationState "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} PATH]}" "${StandardSoftwareRegistrationIndicator[${i}]}")"
            AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTEREDNAME]="${StandardSoftwareRegisteredName[${i}]}"
        else
            AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} PATH]="$(find "${StandardPath}" -type f -name "${StandardSoftwareBinaries[${i}]}" -printf '%h\n' -quit 2>/dev/null || echo "NOTINSTALLED")"
            if [[ "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} PATH]}" != "NOTINSTALLED" ]] && [[ -x "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} PATH]}/${StandardSoftwareBinaries[${i}]}" ]]; then
                ((AllSoftwareInfo[INSTALLEDCOUNTER]+=1))
                AllSoftwareInfo[INSTALLEDNAMES]+="${StandardSoftwareBinaries[${i}]} "
                AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} INSTALLSTATE]="INSTALLEDNONSTANDARD"
                AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} RUNSTATE]="${StandardSoftwareRunStates[${i}]:-UNAVAILABLE}"
                AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTRATIONINFO]="$(FXSUB_GetRegistrationState "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} PATH]}" "${StandardSoftwareRegistrationIndicator[${i}]}")"
                AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTEREDNAME]="${StandardSoftwareRegisteredName[${i}]}"
            else
                ((AllSoftwareInfo[NOTINSTALLEDCOUNTER]+=1))
                AllSoftwareInfo[NOTINSTALLEDNAMES]+="${StandardSoftwareBinaries[${i}]} "
                AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} INSTALLSTATE]="NOTINSTALLED"
                AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} RUNSTATE]="NOTINSTALLED"
            fi
        fi

        if [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} INSTALLSTATE]} != "NOTINSTALLED" ]]; then
            AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} VERSION]="$(
                (
                    ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} PATH]}/${StandardSoftwareBinaries[${i}]} version 2>&1
                    ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} PATH]}/${StandardSoftwareBinaries[${i}]} --version 2>&1
                ) \
                | awk '
                    BEGIN {
                        CVER="UNKNOWN"
                        UVER="UNKNOWN"
                    } {
                        if ($1 ~ "^v[0-9]+.")
                            CVER=$1
                        if (/update.*available/ && $4 ~ "^v[0-9]+.")
                            UVER=$4
                    } END {
                        if (UVER == "UNKNOWN")
                            printf "%s:%s",CVER,CVER
                        else
                            printf "%s:%s",CVER,UVER
                    }
                '
            )"
        fi
    done

    # Parse and print.
    FX_AdvancedPrint $(

        echo -e "COMPLEX:M:${MyScreenWidth}:1:${FBlack};${BGreen}" "SYSTEM\u2000SOFTWARE\u2000INFORMATION"
        echo "NEXT"

        # Software names are used for columns.
        for ((i=0;i<${#StandardSoftwareBinaries[@]};i++)); do
            [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} INSTALLSTATE]} == "NOTINSTALLED" ]] \
                && continue

            MoveToColumn="${TableColumns[$((${ActiveColumn}%${#TableColumns[@]}))]}"

            echo "MOVETO:0:${MoveToColumn}"
            echo "COMPLEX:M:1:0:${FBlue}" "┏"
            echo "COMPLEX:M:$((${MyMaxColumnWidth}-1)):0:${Bold};${BBlue}" "${StandardSoftwareBinaries[${i}]}"
            echo "NEXT"
            ((ActiveLine=2))

            echo "MOVETO:0:${MoveToColumn}"
            if [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} RUNSTATE]%:*} == "RUNNING" ]]; then
                echo "COMPLEX:R:2:0:${FBlue}" "┣┳"
                echo "COMPLEX:L:10:2:${Normal}" "RunState"
                echo -e "COMPLEX:M:$((${MyMaxColumnWidth}-12)):0:${FBlack};${BLiteGreen}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} RUNSTATE]%:*}"
                echo "NEXT"
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:R:3:0:${FBlue}" "┃┗━"
                echo "COMPLEX:L:10:2:${Normal}" "PID"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${FBlack};${Normal}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} RUNSTATE]#*:}"
                echo "NEXT"
                ((ActiveLine+=2))
            elif [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} RUNSTATE]%:*} == "ON-DEMAND" ]]; then
                echo "COMPLEX:R:2:0:${FBlue}" "┣━"
                echo "COMPLEX:L:10:2:${Normal}" "RunState"
                echo -e "COMPLEX:M:$((${MyMaxColumnWidth}-12)):0:${BLiteYellow};${FBlack}" "ON-DEMAND"
                echo "NEXT"
                ((ActiveLine+=1))
            else
                echo "COMPLEX:R:2:0:${FBlue}" "┣━"
                echo "COMPLEX:L:10:2:${Normal}" "RunState"
                echo -e "COMPLEX:M:$((${MyMaxColumnWidth}-12)):0:${FWhite};${BRed}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} RUNSTATE]}"
                echo "NEXT"
                ((ActiveLine+=1))
            fi

            if [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} RUNSTATE]%:*} == "ON-DEMAND" ]] && [[ ${FLAG_ShowAliasInfo:-FALSE} == "FALSE" ]]; then
                PrintTiers=( "┗┳" " ┣━" " ┗━" )
            else
                if [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTRATIONINFO]} == "UNAVAILABLE" ]]; then
                    [[ ${FLAG_ShowAliasInfo:-FALSE} == "FALSE" ]] \
                        && PrintTiers=( "┣┳" "┃┣━" "┃┗━" "┣━" ) \
                        || PrintTiers=( "┣┳" "┃┣━" "┃┗━" "┗━" )
                elif [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTRATIONINFO]} != "UNAVAILABLE" ]]; then
                    [[ ${FLAG_ShowAliasInfo:-FALSE} == "FALSE" ]] \
                        && PrintTiers=( "┣┳" "┃┣━" "┃┗━" "┣┳" ) \
                        || PrintTiers=( "┣┳" "┃┣━" "┃┗━" " ┣━" )
                fi
            fi

            echo "MOVETO:0:${MoveToColumn}"
            echo "COMPLEX:R:2:0:${FBlue}" "${PrintTiers[0]}"
            echo "COMPLEX:L:10:2:${Normal}" "Path"
            if [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} INSTALLSTATE]} == "INSTALLEDNONSTANDARD" ]]; then
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-12)):0:${FLiteRed}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} PATH]}\u2000[NONSTANDARD-LOCATION]"
            else
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-12)):0:${Normal}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} PATH]}"
            fi
            echo "NEXT"
            ((ActiveLine+=1))

            echo "MOVETO:0:${MoveToColumn}"
            if [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} VERSION]%:*} == ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} VERSION]#*:} ]]; then
                echo "COMPLEX:R:3:0:${FBlue}" "${PrintTiers[2]}"
                echo "COMPLEX:L:10:2:${Normal}" "Version"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${Normal}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} VERSION]%:*}"
                echo "NEXT"
                ((ActiveLine+=1))
            else
                echo "COMPLEX:R:3:0:${FBlue}" "${PrintTiers[1]}"
                echo "COMPLEX:L:10:2:${Normal}" "Version"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${FYellow}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} VERSION]%:*}"
                echo "NEXT"
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:R:3:0:${FBlue}" "${PrintTiers[1]}"
                echo "COMPLEX:L:10:2:${Normal}" "AvailVer"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${FGreen}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} VERSION]#*:}"
                echo "NEXT"
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:R:3:0:${FBlue}" "${PrintTiers[2]}"
                echo "COMPLEX:L:10:2:${Normal}" "Info"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-13)):0:${FGreen}" "See\u2000software\u2000HELP\u2000option\u2000for\u2000info."
                echo "NEXT"
                ((ActiveLine+=3))
            fi

            if [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} RUNSTATE]%:*} != "ON-DEMAND" ]] && [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTRATIONINFO]} != "UNREGISTERED" ]]; then
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:R:2:0:${FBlue}" "${PrintTiers[3]}"
                echo "COMPLEX:L:10:2:${Normal}" "IsReg"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-12)):0:${FGreen}" "YES"
                echo "NEXT"
                if [[ ${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTEREDNAME]} != "UNAVAILABLE" ]]; then
                    echo "MOVETO:0:${MoveToColumn}"
                    echo "COMPLEX:R:2:0:${FBlue}" "${PrintTiers[3]}"
                    echo "COMPLEX:L:10:2:${Normal}" "RegName"
                    echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-12)):0:${Normal}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTEREDNAME]}"
                    echo "NEXT"
                    ((ActiveLine+=1))
                fi
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:R:2:0:${FBlue}" "${PrintTiers[3]}"
                echo "COMPLEX:L:10:2:${Normal}" "Identity"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-12)):0:${Normal}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTRATIONINFO]%:*}"
                echo "NEXT"
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:R:2:0:${FBlue}" "${PrintTiers[3]}"
                echo "COMPLEX:L:10:2:${Normal}" "Age"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-12)):0:${Normal}" "${AllSoftwareInfo[${StandardSoftwareBinaries[${i}]} REGISTRATIONINFO]#*:}"
                echo "NEXT"
                ((ActiveLine+=2))
            fi

            if [[ ${FLAG_ShowAliasInfo:-FALSE} == "TRUE" ]]; then
                echo "MOVETO:0:${MoveToColumn}"
                echo "COMPLEX:R:3:0:${FBlue}" "┗┳━"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-3)):0:${Normal}" "Available\u2000Aliases"
                echo "NEXT"
                ((ActiveLine+=1))
            fi

            [[ ${ActiveLine} -ge ${MaxLine} ]] \
                && ((MaxLine=${ActiveLine}))
            if [[ ${FLAG_LimitLoginInfo:-FALSE} != "FALSE" ]] && ! ((--AllSoftwareInfo[INSTALLEDCOUNTER])) || [[ $(((${ActiveColumn}+1)%${#TableColumns[@]})) -eq 0 ]]; then
                [[ ${MaxLine} -gt ${ActiveLine} ]] \
                    && echo "MOVETO:$((${MaxLine}-${ActiveLine})):0"
                [[ ${FLAG_LimitLoginInfo:-FALSE} != "FALSE" ]] || [[ $(((${ActiveColumn}+1)%${#TableColumns[@]})) -eq 0 ]] \
                    && ((MaxLine=0))
            else
                echo "MOVETO:-${ActiveLine}:0"
            fi

            echo "NEXT"
            ((ActiveColumn+=1))
        done

        if [[ ${FLAG_ShowAliasInfo:-FALSE} == "FALSE" ]] || [[ ${FLAG_LimitLoginInfo:-FALSE} == "FALSE" ]]; then
            # Done processing installed software, now on to those that are not.
            MoveToColumn="${TableColumns[$((${ActiveColumn}%${#TableColumns[@]}))]}"

            echo "MOVETO:0:${MoveToColumn}"
            echo "COMPLEX:M:1:0:${FBlue}" "┏"
            echo -e "COMPLEX:M:$((${MyMaxColumnWidth}-1)):0:${Bold};${BBlue}" "UNAVAILABLE\u2000SOFTWARE"
            echo "NEXT"
            ((ActiveLine=2))

            for EachSoftware in ${AllSoftwareInfo[NOTINSTALLEDNAMES]:-NONE}; do
                echo "MOVETO:0:${MoveToColumn}"
                ! ((--AllSoftwareInfo[NOTINSTALLEDCOUNTER])) \
                    && echo "COMPLEX:R:2:0:${FBlue}" "┗━" \
                    || echo "COMPLEX:R:2:0:${FBlue}" "┣━"
                echo "COMPLEX:L:10:2:${Normal}" "Name"
                echo -e "COMPLEX:L:$((${MyMaxColumnWidth}-12)):0:${Normal}" "${EachSoftware}"
                echo "NEXT"
                ((ActiveLine+=1))
            done
        fi

        [[ ${ActiveLine} -gt ${MaxLine} ]] \
            && ((MaxLine=${ActiveLine}))
        echo "MOVETO:$((${MaxLine}-${ActiveLine})):0"
    )

    return 0
}

#########################
# Logo Printer.
FX_LogoMessaging() {
    # Expecting 1/ThisLogo, 2/MessageA, 3/MessageB.
    local ThisLogo="${1}" ThisMessageA="${2}" ThisMessageB="${3}"

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
        "END"

    return 0
}

##################################################
## MAIN                                         ##
##################################################
# Do not run if not interactive.
[[ -n "${PS1}" ]] \
    && exit 0

#########################
# The MAIN section.
if FX_PreLoginCheck; then
    # ROOT.
    FX_LogoMessaging "${SystemLogo}" "${SystemLoginMessaging[0]}" "${SystemLoginMessaging[1]}" # Print logo and relevant messaging.
    FX_IPInfo # Get IP related information.
    FX_UserAccessReview "${FLAG_OPT_UserAccessReview:-3}" # Show login access (FAILEDCURRENT or #MONTHS+CURRENT).
    FX_SocketInfo # List all active sockets maintained by the system.
    #FX_SoftwareCheck # Check a list of software for availability and runtime state.
else
    # NONROOT.
    FX_LogoMessaging "${SystemLogo}" "${SystemLoginMessaging[0]}" "${SystemLoginMessaging[1]}" # Print logo and relevant messaging.
fi

echo
stty sane 2>/dev/null
####################################################################################################
# EOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOF #
####################################################################################################