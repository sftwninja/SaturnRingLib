import json
import re
import argparse

def parse_uts_log(log_file):
    testcases = []
    total_tests = 0
    total_failures = 0

    with open(log_file, 'r') as file:
        lines = file.readlines()
        i = 0
        while i < len(lines):
            line = lines[i]

            # Match passed tests
            passed_match = re.match(r"TESTING : Passed :(.*)", line)
            if passed_match:
                testcases.append({
                    "name": passed_match.group(1).strip(),
                    "classname": passed_match.group(1).split('_')[0],
                    "status": "passed"
                })
                total_tests += 1

            # Match failed tests (read two lines)
            failed_match = re.match(r"FATAL : (.*) failed:", line)
            if failed_match and i + 1 < len(lines):
                details_line = lines[i + 1].strip()
                details_match = re.match(r"(.*):(\d+): (.*)", details_line)
                if details_match:
                    testcases.append({
                        "name": failed_match.group(1).strip(),
                        "classname": failed_match.group(1).split('_')[0],
                        "status": "failed",
                        "failure": {
                            "message": details_match.group(3).strip(),
                            "file": details_match.group(1).strip(),
                            "line": int(details_match.group(2))
                        }
                    })
                    total_tests += 1
                    total_failures += 1
                i += 1  # Skip the details line

            i += 1


    testsuites = {
        "summary": {
        "name": "SaturnRingLib Unit Tests",
        "tests": total_tests,
        "failures": total_failures,
        "errors": total_failures,
        "skipped": 0
    },
    "tool": {
            "name": "minunit"
        },
        "tests": testcases
    }


    return {
        "reportFormat": "CTRF",
        "specVersion": "0.0.0",
        "results": testsuites
    }


def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Convert uts.log to JSON format.")
    parser.add_argument("log_file", help="Path to the uts.log file")
    parser.add_argument("output_file", help="Path to the output JSON file")
    args = parser.parse_args()

    # Parse the log file
    report = parse_uts_log(args.log_file)

    # Write the JSON report
    with open(args.output_file, 'w') as json_file:
        json.dump(report, json_file, indent=4)

    print(f"Conversion complete. JSON report saved to {args.output_file}")


if __name__ == "__main__":
    main()