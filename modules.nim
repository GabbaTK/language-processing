import tables

type
    anyType* = object
        intValue*: int
        strValue*: string = ""
        boolValue*: bool
        dictValue*: Table[string, anyType]

proc echoR*(msg: string) = echo "\e[31m" & msg & "\e[0m"
proc echoG*(msg: string) = echo "\e[32m" & msg & "\e[0m"
proc echoY*(msg: string) = echo "\e[33m" & msg & "\e[0m"
proc echoB*(msg: string) = echo "\e[34m" & msg & "\e[0m"
proc echoM*(msg: string) = echo "\e[35m" & msg & "\e[0m"
proc echoC*(msg: string) = echo "\e[36m" & msg & "\e[0m"
proc echoW*(msg: string) = echo "\e[37m" & msg & "\e[0m"
proc rawEcho*(msg: string) = write(stdout, msg)
proc echoInput*(msg: string): string = write(stdout, msg); return readLine(stdin)