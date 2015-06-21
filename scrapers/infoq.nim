import httpclient, nre, options, sequtils, marshal, streams, strutils

type Video = tuple [title: string, url: string, image: string, author: string, description: string]


proc downloadAndParse(url: string): tuple[res:seq[Video], count:int] =
        stderr.write("Downlowding $1\n" % url)
        var res = newSeq[Video]()
        var html = getContent(url)
        stderr.write("Downlowding Done\n")
        #var html = readFile("infoq.html")

        var regexp = re"""(?s)<div class="news_type_video.*?href="(.*?)".*?title="(.*?)".*?<img src="(.*?).*?<span class="author">.*?title="(.*?)".*?<p>\s*(.*?)</p>"""

        type State = enum
                Out, InDiv, UrlDone, TitleDone, ImageDone, DescriptionStart
        var count = 0
        var state = Out

        var title, url, image, author, description: string

        for ln in splitLines(html):


                if state == Out and ln.match(re""".*<div class="news_type_video""").isSome == true:
                        state = InDiv
                        continue
                if state == InDiv and ln.match(re""".*href="(.*?)"""").isSome == true:
                        url = ln.match(re""".*href="(.*?)"""").get.captures[0]
                        state = UrlDone
                        continue
                if state == UrlDone and ln.match(re""".*title=".*?"""").isSome == true:
                        title = ln.match(re""".*title="(.*?)"""").get.captures[0]
                        state = TitleDone
                        continue
                if state == TitleDone and ln.match(re""".*<img.*?src=".*?"""").isSome == true:
                        image = ln.match(re""".*<img.*?src="(.*?)"""").get.captures[0]
                        state = ImageDone
                        continue
                if state == ImageDone and ln.match(re""".*<p>""").isSome == true:
                        state = DescriptionStart
                        description = ""
                        continue

                if state == DescriptionStart:
                        if ln.match(re""".*</p>""").isSome == true:
                                state = Out
                                var v:Video = (title, url, image, "", description)
                                res.add(v)
                                count = count + 1
                                continue
                        description.add(ln)
                        continue

        (res, count)





var total = newSeq[Video]()
var totalCount = 0

var counter = 0
var url = "http://www.infoq.com/presentations/"
var index = ""
while true:
        var (s, count) = downloadAndParse(url & index)
        if count == 0:break
        counter = counter + 1
        var fs = newFileStream("index$1" % intToStr(counter), fmWrite)
        store(fs, s)
        close(fs)
        total = concat(total, s)
        totalCount = totalCount + count
        index = intToStr(totalCount)





var fs = newFileStream(stdout)

store(fs, total)



