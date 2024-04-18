#[
    raw number (1, 2, 3)
    text based number (jedan, dva, tri)
    ordinal numbers (prvi, drugi, treći)
]#

import tables
import strutils
import strformat
import modules

# Variables needed to parse number words
var textualNumbersStartingWords = ["jedan", "dva", "tri", "cetiri", "pet", "sest", "sedam", "osam", "devet", "nula", "jedanaest", "dvanaest", "trinaest", "cetrnaest", "petnaest", "sestnaest", "sedamnaest", "osamnaest", "devetnaest", "deset", "dvadeset", "trideset", "cetrdeset", "pedeset", "sezdeset", "sedamdeset", "osamdeset", "devedeset", "sto", "dvjesto", "tristo", "cetiristio", "petsto", "sesto", "sedamsto", "osamsto", "devetsto", "tisucu", "tisuca", "tisuce", "jedna", "dvije", "milijun", "milijuna"]
var textualNumbersOneChar = ["jedan", "dva", "tri", "cetiri", "pet", "sest", "sedam", "osam", "devet", "nula"]
var textualNumbersTenToNineteenChars = ["jedanaest", "dvanaest", "trinaest", "cetrnaest", "petnaest", "sestnaest", "sedamnaest", "osamnaest", "devetnaest"]
var textualNumbersTwoChar = {"origin": "deset", "one": "", "two": "dva", "three": "tri", "four": "cetr", "five": "pe", "six": "sez", "seven": "sedam", "eight": "osam", "nine": "deve"}
var textualNumbersThreeChar = {"origin": "sto", "one": "", "two": "dvje", "three": "tri", "four": "cetiri", "five": "pet", "six": "se", "seven": "sedam", "eight": "osam", "nine": "devet"}
var textualNumbersFourChar = ["jedna", "dvije", "tri", "cetiri", "pet", "sest", "sedam", "osam", "devet"]
var textualNumbersFourCharHeader = {"basic": "tisuca", "one": "tisuca", "above": "tisuce"}
var textualNumbersFiveChar = ["jedan", "dva", "tri", "cetiri", "pet", "sest", "sedam", "osam", "devet"]
var textualNumbersFiveCharHeader = {"basic": "milijun", "one": "milijun", "above": "milijuna"}

proc rawNumber*(message: string): seq[Table[string, anyType]] =
    var message = $message
    message &= "\x00" # Add a null-byte to also check if the last item is an int

    var decipheredNumber = anyType()
    var decimalNumber = anyType()
    var readingNumber = false
    var readingDecimal = false
    var switchingReading = false
    var entities: seq[Table[string, anyType]]

    echoM("Detecting (     RAW NUMBER     ) values")

    for char in message:
        try:
            discard parseInt($char)
            readingNumber = true

            if readingDecimal:
                decimalNumber.strValue &= char
            else:
                decipheredNumber.strValue &= char
        except ValueError:
            if char == '.':
                readingDecimal = true

            elif readingNumber:
                readingNumber = false
                readingDecimal = false
                switchingReading = true

        # Done reading this series of numbers
        if switchingReading:
            switchingReading = false

            if decimalNumber.strValue == "":
                decimalNumber.strValue = "0"

            echoG(fmt"Found value: ( {decipheredNumber.strValue}.{decimalNumber.strValue} )")

            var entity = initTable[string, anyType]()

            var value = anyType(strValue: "number")
            entity["type"] = value

            value = anyType(intValue: parseInt(decipheredNumber.strValue))
            entity["value"] = value

            value = anyType(intValue: parseInt(decimalNumber.strValue))
            entity["decimal"] = value

            entities.add(entity)
            decipheredNumber = anyType()
            decimalNumber = anyType()

    return entities

proc getTextualNumberSegment(word: string): string =
    var validWords: seq[string]
    var longest = ""

    for testWord in textualNumbersStartingWords:
        if testWord in word:
            validWords.add(testWord)

    for word in validWords:
        if word.len > longest.len:
            longest = word

    return longest

proc textualNumber*(message: string): seq[Table[string, anyType]] =
    var message = $message
    message = toLowerAscii(message)
    message &= "\x00" # Add a null-byte to also check if the last item is a part of the number based string

    message = message.replace("š", "s")
    message = message.replace("đ", "d")
    message = message.replace("č", "c")
    message = message.replace("ć", "c")
    message = message.replace("ž", "z")

    var readingNumber = false
    var validWord = false
    var wordGroups: seq[seq[string]]
    var wordGroup: seq[string]

    echoM("Detecting (   TEXTUAL NUMBER   ) values")

    # First seperate the message into number segments
    var words = message.split(" ")

    for word in words:
        for testNumber in textualNumbersStartingWords:
            if testNumber in word:
                readingNumber = true
                validWord = true
                
                var maybeSelectedWord = getTextualNumberSegment(word)

                if not (maybeSelectedWord in word):
                    echoR(fmt"Longest word is not the selected word! ( longest: {maybeSelectedWord}, actual: {word} )")

                if not (maybeSelectedWord in wordGroup):
                    wordGroup.add(maybeSelectedWord)

        if validWord:
            validWord = false
        else:
            if readingNumber:
                readingNumber = false

                var foundNumbers = join(wordGroup, " ")
                echoG(fmt"Found value: ( {foundNumbers} )")

                wordGroups.add(wordGroup)
                wordGroup = @[]

    echo wordGroups

echo textualNumber("Bok, ja sada imam trinaest godina, i ovo je neki broj! Tri milijuna petsto trideset dvije tisuće petsto osamdeset. sup")