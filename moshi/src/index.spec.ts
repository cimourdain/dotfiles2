import { AxiosResponse } from "axios";
import { expect } from "chai";
import { describe, it } from "mocha";
import { Request } from "./lib/request";
import { BFFTester, Brand } from "./wlac";

function validateRecommendationEstimationFunnelIWB(
  response: AxiosResponse<any, any>
): boolean {
  describe("Validate Recommendation Estimation Funnel response for IWB", function () {
    it("should return 21 agencies", function () {
      expect(response.data).have.property("agencies");
      expect(response.data.agencies).with.lengthOf(20);
    });
  });
  return true;
}

describe("Recommendation Estimation Funnel IWB", function () {
  this.timeout(0);
  it("Test Immoweb Recommendation Estimation Funnel with random data", async function () {
    const bff_dev = new Request(
      "https://agency-card-bff.assured-muskrat-dev.aws.aviv.eu"
    );

    const bff = new BFFTester(bff_dev);
    await bff.testRecommendationEstimationFunnel(
      Brand.IMMOWEB,
      {},
      validateRecommendationEstimationFunnelIWB
    );
  });
});
