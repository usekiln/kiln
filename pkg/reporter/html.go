// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package reporter

import (
	"fmt"
	"html/template"
	"os"

	"github.com/usekiln/kiln/pkg/scanner"
)

const htmlTemplate = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kiln Compliance Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f5f5;
            padding: 40px 20px;
            line-height: 1.6;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header .emoji { font-size: 3em; }
        .score-section {
            background: #f8f9fa;
            padding: 30px;
            text-align: center;
            border-bottom: 3px solid #e9ecef;
        }
        .score-circle {
            width: 200px;
            height: 200px;
            margin: 0 auto 20px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 4em;
            font-weight: bold;
            color: white;
        }
        .score-excellent { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        .score-good { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
        .score-fair { background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%); color: #333; }
        .score-poor { background: linear-gradient(135deg, #ff9a9e 0%, #fad0c4 100%); color: #333; }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px;
            background: white;
        }
        .summary-card {
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        .summary-card .number {
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .summary-card .label {
            color: #6c757d;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .card-passed { background: #d4edda; color: #155724; }
        .card-warnings { background: #fff3cd; color: #856404; }
        .card-violations { background: #f8d7da; color: #721c24; }
        .section {
            padding: 30px;
            border-top: 1px solid #e9ecef;
        }
        .section h2 {
            margin-bottom: 20px;
            color: #333;
        }
        .finding {
            background: #f8f9fa;
            padding: 20px;
            margin-bottom: 15px;
            border-radius: 6px;
            border-left: 4px solid #6c757d;
        }
        .finding-critical { border-left-color: #dc3545; background: #f8d7da; }
        .finding-high { border-left-color: #fd7e14; background: #fff3cd; }
        .finding-medium { border-left-color: #ffc107; background: #fff3cd; }
        .finding-low { border-left-color: #17a2b8; background: #d1ecf1; }
        .finding-passed { border-left-color: #28a745; background: #d4edda; }
        .finding-header {
            display: flex;
            align-items: center;
            margin-bottom: 10px;
        }
        .finding-icon {
            font-size: 1.5em;
            margin-right: 10px;
        }
        .finding-control {
            font-weight: bold;
            color: #495057;
            margin-right: 10px;
        }
        .finding-message {
            color: #212529;
            flex: 1;
        }
        .finding-details {
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px solid #dee2e6;
            font-size: 0.9em;
            color: #6c757d;
        }
        .finding-resource {
            font-family: monospace;
            background: white;
            padding: 5px 10px;
            border-radius: 4px;
            display: inline-block;
            margin-top: 5px;
        }
        .finding-remediation {
            margin-top: 10px;
            padding: 10px;
            background: white;
            border-radius: 4px;
            font-size: 0.9em;
        }
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #6c757d;
            font-size: 0.9em;
            border-top: 1px solid #e9ecef;
        }
        .timestamp {
            color: #6c757d;
            font-size: 0.9em;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="emoji">🔥</div>
            <h1>Kiln Compliance Report</h1>
            <p>SOC2 Trust Service Criteria Analysis</p>
        </div>

        <div class="score-section">
            <div class="score-circle {{.ScoreClass}}">
                {{.Score}}%
            </div>
            <h2>Audit Readiness Score</h2>
            <p class="timestamp">Scanned: {{.ScannedAt}}</p>
        </div>

        <div class="summary">
            <div class="summary-card card-passed">
                <div class="number">{{.PassedCount}}</div>
                <div class="label">Controls Passing</div>
            </div>
            <div class="summary-card card-warnings">
                <div class="number">{{.WarningCount}}</div>
                <div class="label">Warnings</div>
            </div>
            <div class="summary-card card-violations">
                <div class="number">{{.ViolationCount}}</div>
                <div class="label">Critical Gaps</div>
            </div>
        </div>

        {{if .Violations}}
        <div class="section">
            <h2>❌ Critical Control Gaps</h2>
            {{range .Violations}}
            <div class="finding finding-{{.Severity}}">
                <div class="finding-header">
                    <span class="finding-icon">❌</span>
                    <span class="finding-control">{{.Control}}</span>
                    <span class="finding-message">{{.Message}}</span>
                </div>
                {{if .Resource}}
                <div class="finding-details">
                    <strong>Resource:</strong>
                    <div class="finding-resource">{{.Resource}}</div>
                </div>
                {{end}}
                {{if .Remediation}}
                <div class="finding-remediation">
                    <strong>💡 How to fix:</strong> {{.Remediation}}
                </div>
                {{end}}
            </div>
            {{end}}
        </div>
        {{end}}

        {{if .Warnings}}
        <div class="section">
            <h2>⚠️ Warnings (Auditor Recommendations)</h2>
            {{range .Warnings}}
            <div class="finding finding-{{.Severity}}">
                <div class="finding-header">
                    <span class="finding-icon">⚠️</span>
                    <span class="finding-control">{{.Control}}</span>
                    <span class="finding-message">{{.Message}}</span>
                </div>
                {{if .Resource}}
                <div class="finding-details">
                    <strong>Resource:</strong>
                    <div class="finding-resource">{{.Resource}}</div>
                </div>
                {{end}}
                {{if .Remediation}}
                <div class="finding-remediation">
                    <strong>💡 Recommendation:</strong> {{.Remediation}}
                </div>
                {{end}}
            </div>
            {{end}}
        </div>
        {{end}}

        {{if .Passed}}
        <div class="section">
            <h2>✅ Controls Implemented ({{.PassedCount}})</h2>
            {{range .Passed}}
            <div class="finding finding-passed">
                <div class="finding-header">
                    <span class="finding-icon">✅</span>
                    <span class="finding-control">{{.Control}}</span>
                    <span class="finding-message">{{.Message}}</span>
                </div>
                {{if .Resource}}
                <div class="finding-details">
                    <strong>Resource:</strong>
                    <div class="finding-resource">{{.Resource}}</div>
                </div>
                {{end}}
            </div>
            {{end}}
        </div>
        {{end}}

        <div class="footer">
            <p><strong>Important:</strong> Kiln identifies potential control gaps. It does not certify SOC2 compliance.</p>
            <p>A formal audit by a licensed CPA firm is required for SOC2 compliance.</p>
            <p style="margin-top: 15px;">Generated by Kiln v0.1.0 • <a href="https://github.com/usekiln/kiln">github.com/usekiln/kiln</a></p>
        </div>
    </div>
</body>
</html>`

// PrintHTML outputs scan results as an HTML report
func PrintHTML(result *scanner.Result, outputFile string) {
	if outputFile == "" {
		fmt.Println("❌ Error: --output flag is required for HTML format")
		fmt.Println("   Example: kiln scan main.tf --format html --output report.html")
		os.Exit(1)
	}

	// Prepare template data
	data := map[string]interface{}{
		"Score":          result.Score,
		"ScoreClass":     getScoreClass(result.Score),
		"ScannedAt":      result.ScannedAt,
		"PassedCount":    len(result.Passed),
		"WarningCount":   len(result.Warnings),
		"ViolationCount": len(result.Violations),
		"Violations":     result.Violations,
		"Warnings":       result.Warnings,
		"Passed":         result.Passed,
	}

	// Parse and execute template
	tmpl, err := template.New("report").Parse(htmlTemplate)
	if err != nil {
		fmt.Printf("❌ Error creating template: %v\n", err)
		os.Exit(1)
	}

	// Create output file
	file, err := os.Create(outputFile)
	if err != nil {
		fmt.Printf("❌ Error creating file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	// Write report
	err = tmpl.Execute(file, data)
	if err != nil {
		fmt.Printf("❌ Error writing report: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✅ HTML report saved to: %s\n", outputFile)
}

func getScoreClass(score int) string {
	if score >= 80 {
		return "score-excellent"
	} else if score >= 60 {
		return "score-good"
	} else if score >= 40 {
		return "score-fair"
	}
	return "score-poor"
}
