// SPDX-License-Identifier: AGPL-3.0-or-later
package cmd

import "testing"

// Reuse the backported integration regressions without running unrelated suites.
func TestOpenImageSecurity(t *testing.T) {
	globalServerCtxt.StrictS3Compat = true
	suite := &TestSuiteCommon{serverType: "ErasureSD", signer: signerV4}
	c := &check{t, suite.serverType}
	suite.SetUpSuite(c)
	defer suite.TearDownSuite(c)
	suite.TestUnsignedCVE(c)
	suite.TestUnsignedQueryStringCVE(c)
	suite.TestUnsignedQueryStringCVEMultipart(c)
	suite.TestUnsignedTrailerRejectsMultipleAuthSources(c)
	suite.TestAnonymousUnsignedTrailer(c)
	suite.TestUnsignedTrailerSnowballRequiresSignature(c)
	suite.TestUnsignedTrailerSnowballAnonymousDenied(c)
	suite.TestUnsignedTrailerSnowballExtract(c)
}
