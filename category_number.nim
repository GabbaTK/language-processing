#[
    raw number (1, 2, 3)
    text based number (jedan, dva, tri)
    ordinal numbers (prvi, drugi, treći)
]#

import tables
import strutils
import strformat
import std/enumerate
import modules

# Variables needed to parse number words
var numberToInt = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "zero": 0, "eleven": 1, "twelve": 2, "thirteen": 3, "fourteen": 4, "fifteen": 5, "sixteen": 6, "seventeen": 7, "eighteen": 8, "nineteen": 9}.toTable()

var textualNumbersStartingWords = ["jedan", "dva", "tri", "cetiri", "pet", "sest", "sedam", "osam", "devet", "nula", "jedanaest", "dvanaest", "trinaest", "cetrnaest", "petnaest", "sestnaest", "sedamnaest", "osamnaest", "devetnaest", "deset", "dvadeset", "trideset", "cetrdeset", "pedeset", "sezdeset", "sedamdeset", "osamdeset", "devedeset", "sto", "dvjesto", "tristo", "cetiristio", "petsto", "sesto", "sedamsto", "osamsto", "devetsto", "tisucu", "tisuca", "tisuce", "jedna", "dvije", "milijun", "milijuna"]
var textualNumbersOneChar = {"one": "jedan", "two": "dva", "three": "tri", "four": "cetiri", "five": "pet", "six": "sest", "seven": "sedam", "eight": "osam", "nine": "devet", "zero": "nula"}.toTable()
var textualNumbersTenToNineteenChars = {"eleven": "jedanaest", "twelve": "dvanaest", "thirteen": "trinaest", "fourteen": "cetrnaest", "fifteen": "petnaest", "sixteen": "sestnaest", "seventeen": "sedamnaest", "eighteen": "osamnaest", "nineteen": "devetnaest"}.toTable()
var textualNumbersTwoChar = {"origin": "deset", "one": "", "two": "dva", "three": "tri", "four": "cetr", "five": "pe", "six": "sez", "seven": "sedam", "eight": "osam", "nine": "deve"}.toTable()
var textualNumbersThreeChar = {"origin": "sto", "one": "", "two": "dvje", "three": "tri", "four": "cetiri", "five": "pet", "six": "se", "seven": "sedam", "eight": "osam", "nine": "devet"}.toTable()
var textualNumbersFourChar = {"one": "jedna", "two": "dvije", "three": "tri", "four": "cetiri", "five": "pet", "six": "sest", "seven": "sedam", "eight": "osam", "nine": "devet"}.toTable()
var textualNumbersFourCharHeader = {"basic": "tisuca", "one": "tisuca", "above": "tisuce"}.toTable()
var textualNumbersFiveChar = {"one": "jedan", "two": "dva", "three": "tri", "four": "cetiri", "five": "pet", "six": "sest", "seven": "sedam", "eight": "osam", "nine": "devet"}.toTable()
var textualNumbersFiveCharHeader = {"basic": "milijun", "one": "milijun", "above": "milijuna"}.toTable()

proc rawNumber*(message: string): seq[Table[string, anyType]] =
    var message = $message
    message &= "\x00" # Add a null-byte to also check if the last item is an int

    var decipheredNumber = anyType()
    var decimalNumber = anyType()
    var readingNumber = false
    var readingDecimal = false
    var switchingReading = false
    var entities: seq[Table[string, anyType]]
    var startIndex = -1
    var endIndex = -1

    echoM("Detecting (     RAW NUMBER     ) values")

    for index, char in enumerate(message):
        try:
            discard parseInt($char)
            readingNumber = true

            if startIndex == -1:
                startindex = index

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

            endIndex = index - 1

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

            value = anyType(intValue: startIndex)
            entity["start"] = value

            value = anyType(intValue: endIndex)
            entity["end"] = value

            entities.add(entity)
            decipheredNumber = anyType()
            decimalNumber = anyType()
            startIndex = -1
            endIndex = -1

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
    message &= " \x00" # Add a space-null to also check if the last item is a part of the number based string

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

    # Parse the number groups to actual numbers
    for group in wordGroups:
        var parsedNumber = anyType()
        var addedHundred = false
        var addedTen = false
        var addedOne = false

        for word in group:
            # Check for hundereds
            for number in ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]:
                if word == textualNumbersThreeChar["origin"] & textualNumbersThreeChar[number]:
                    addedHundred = true
                    parsedNumber.strValue &= $numberToInt[number]
            
            # Check for tens
            for number in ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]:
                if word == textualNumbersTwoChar["origin"] & textualNumbersTwoChar[number]:
                    addedTen = true
                    parsedNumber.strValue &= $numberToInt[number]

            # Check for eleven to nineteen
            for number in ["eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]:
                if word == textualNumbersTenToNineteenChars[number]:
                    addedTen = true
                    parsedNumber.strValue &= "1"
                    parsedNumber.intValue = numberToInt[number] # Carry to ones

            if addedHundred and not addedTen:
                parsedNumber.strValue &= "0"

            # Check for ones
            for number in ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "zero"]:
                if word == textualNumbersOneChar[number]:
                    addedOne = true
                    parsedNumber.strValue &= $numberToInt[number]

            if (addedHundred or addedTen) and not addedOne:
                parsedNumber.strValue &= $parsedNumber.intValue

        echo parsedNumber.strValue

echo textualNumber("Bok, ja sada imam 13 godina, i ovo je neki broj! Sto dvadeset tri i imamo Tristo pedeset osam, a možda i petsto osamnaest")