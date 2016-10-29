proc type s {
    sleep .2
    foreach c [split $s ""] {
        send $c
        expect -re .
    }
}

proc respond { w r } {
    expect $w
    type $r
}

proc pdset {} {
    respond "YOU MAY HAVE TO :PDSET" "\032"
    respond "Fair" ":pdset\r"
    set t [timestamp]
    respond "PDSET" [expr [timestamp -seconds $t -format "%Y"] / 100]C
    type [timestamp -seconds $t -format "%y%m%dD"]
    type [timestamp -seconds $t -format "%H%M%ST"]
    type "!."
    expect "DAYLIGHT SAVINGS" {
        type "N"
	respond "IT IS NOW" "Q"
    } "IT IS NOW" {
        type "Q"
    }
    expect ":KILL"
}

proc shutdown {} {
    respond "*" ":lock\r"
    expect "_"
    send "5kill"
    respond "GO DOWN?\r\n" "y"
    respond "BRIEF MESSAGE" "\003"
    respond "NOW IN DDT" "\005"
}

spawn pdp10 build/simh/init

respond "sim>" "b tu1\r"
respond "MTBOOT" "mark\033g"
respond "Format pack on unit #" "0"
respond "Are you sure you want to format pack on drive" "y"
respond "Pack no?" "0\r"
respond "Verify pack?" "n"
respond "Alloc?" "3000\r"
respond "ID?" "foobar\r"
respond "DDT" "tran\033g"
respond "onto unit" "0"
respond "OK" "y"
expect "EOT"
respond "DDT" "\005"

respond "sim>" "b tu2\r"
respond "MTBOOT" "\033g"
respond "DSKDMP" "l\033ddt\r"
expect "\n"; type "t\033its rp06\r"
expect "\n"; type "\033u"
respond "DSKDMP" "m\033salv rp06\r"
expect "\n"; type "d\033its\r"
expect "\n"; type "its\r"
expect "\n"; type "\033g"
pdset
respond "*" ":ksfedr\r"
respond "File not found" "create\r"
expect -re {Directory address: ([0-7]*)\r\n}
set dir $expect_out(1,string)
type "write\r"
respond "Are you sure" "yes\r"
respond "Which file" "bt\r"
respond "Input from" ".;bt rp06\r"
respond "!" "quit\r"
expect ":KILL"
shutdown

respond "sim>" "b tu1\r"
respond "MTBOOT" "feset\033g"
respond "on unit #" "0"
respond "address: " "$dir\r"
respond "DDT" \005
respond "sim>" "quit"

spawn pdp10 build/simh/boot
respond "DSKDMP" "its\r"
type "\033g"
pdset
respond "*" ":midas system;_its\r"
respond "MACHINE NAME =" "AI\r"
expect ":KILL"
shutdown
respond "sim>" "quit"
