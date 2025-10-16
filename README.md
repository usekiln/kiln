# Kiln
   
   **Infrastructure scanner for SOC2 Trust Service Criteria**

   Kiln scans your Terraform files for SOC2 Trust Service Criteria violations and helps you prepare for SOC2 audits by letting you harden your infrastructure before you deploy.
   
   ## ⚠️ Important Disclaimer

   **Kiln is a scanning tool, not a compliance certification service.**

   Kiln helps you identify potential gaps in your infrastructure against SOC2 Trust Service Criteria. However:

   - ✋ Kiln does NOT certify or guarantee SOC2 compliance
   - ✋ Kiln does NOT replace a formal SOC2 audit
   - ✋ Kiln does NOT make your organization "SOC2 compliant"

   What Kiln DOES do:
   - ✅ Scans infrastructure code against SOC2 Trust Service Criteria
   - ✅ Identifies potential control gaps before your auditor does
   - ✅ Provides actionable remediation guidance
   - ✅ Tracks your progress toward audit readiness
   - ✅ Helps you prepare for a SOC2 audit
   
   ## Quick Start
```bash
   go install github.com/usekiln/kiln/cmd/kiln@latest
   kiln scan main.tf
```
   
   ## Status
   
   Early development. Not ready for production use.

   ## License
   
   Kiln is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

   This permissive license allows you to:
   - Use Kiln commercially
   - Modify the source code
   - Distribute your modifications
   - Use Kiln privately

   We chose Apache 2.0 to maximize adoption and encourage community contributions.