from xml.etree import ElementTree
import datetime


# disable all known XML attacks
# All of them depend on the DOCTYPE/DTD
# https://docs.python.org/2/library/xml.html#xml-vulnerabilities
def checkXMLSafe(data):
    assert "<!DOCTYPE" not in data


def robot_xml_to_perf_rows(project_name, build_id, openfile):
    data = openfile.read()
    checkXMLSafe(data)
    rows = []

    els = ElementTree.fromstring(data)
    for suite in els.findall("suite"):
        suite_name = suite.get("name")
        for test in suite.findall("test"):
            test_name = test.get("name")
            for kw in test.findall("kw"):
                kw_name = kw.get("name")
                for message in kw.findall("msg"):
                    if message.text.startswith("#perfmetrics"):
                        timestamp = message.get("timestamp")
                        timestamp = parsedatetime(timestamp).isoformat()
                        robot_tag, python_tag = "", ""

                        for line in message.text.split("\n"):
                            if len(line) == 0:
                                pass
                            elif line.startswith("#perfmetrics"):
                                pass  # TODO
                            elif line == "#metrics,totalTime,totalCalls":
                                pass
                                # just being a bit paranoid about changes in the format/columns
                            elif line[0] == "#":
                                assert False, "Unexpected comment line %s" % line
                            else:
                                metrics, totalTime, totalCalls = line.split(",")
                                rows.append(
                                    [
                                        project_name,
                                        build_id,
                                        suite_name,
                                        test_name,
                                        kw_name,
                                        robot_tag,
                                        python_tag,
                                        timestamp,
                                        metrics,
                                        totalTime,
                                        totalCalls,
                                    ]
                                )
    return rows


def parsedatetime(date_string):
    return datetime.datetime.strptime(date_string, r"%Y%m%d %H:%M:%S.%f")


for row in robot_xml_to_perf_rows("build-xyzzy", "git-commit-xyz", open("output.xml")):
    print(",".join(row))
