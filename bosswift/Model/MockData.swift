import Foundation

enum MockData {
    static let projects: [Project] = [
    ]
    
    static let consoleOutput: ConsoleOutput = {
        let output = ConsoleOutput()
        output.output(line: "PING baidu.com (220.181.38.148): 56 data bytes")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=0 ttl=53 time=25.805 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=1 ttl=53 time=27.785 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=2 ttl=53 time=25.914 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=3 ttl=53 time=27.462 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=4 ttl=53 time=27.321 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=5 ttl=53 time=26.542 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=6 ttl=53 time=25.329 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=7 ttl=53 time=26.479 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=8 ttl=53 time=26.779 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=9 ttl=53 time=28.043 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=10 ttl=53 time=26.243 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=11 ttl=53 time=26.329 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=12 ttl=53 time=26.273 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=13 ttl=53 time=28.920 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=14 ttl=53 time=26.569 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=15 ttl=53 time=25.875 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=16 ttl=53 time=29.638 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=17 ttl=53 time=28.149 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=18 ttl=53 time=25.610 ms")
        output.output(line: "64 bytes from 220.181.38.148: icmp_seq=19 ttl=53 time=25.807 ms")
        
        return output
    }()
}
