import { faker } from "@faker-js/faker";
import { AxiosResponse } from "axios";
import { expect } from "chai";
import { Request, responseValidatorCallbackType } from "./lib/request";
import chalk = require("chalk");

export enum Brand {
  LOGICIMMO = "LI",
  IMMOWEB = "IWB",
  SELOGER = "SL",
}

type CoordinatesRequest = {
  lat?: number;
  lng?: number;
};

type RecommendationQueryParamsRequestCommon = {
  estimationId?: string;
  price?: number;
  propertyType?: string;
};

type BELocalizationRequest = CoordinatesRequest & {
  zipCode?: string;
};

type RecommendationQueryParamsRequestIWB =
  RecommendationQueryParamsRequestCommon & BELocalizationRequest;

type FRLocalizationRequest = CoordinatesRequest & {
  legacyAddressId?: number;
};

type RecommendationQueryParamsRequestMALegacy =
  RecommendationQueryParamsRequestCommon & FRLocalizationRequest;

type Coordinates = {
  lat: number;
  lng: number;
};

type RecommendationQueryParamsCommon =
  RecommendationQueryParamsRequestCommon & {
    estimationId: string;
    price: number;
    propertyType: string;
  };

type BELocalization = Coordinates & {
  zipCode: string;
};

type RecommendationQueryParamsIWB = RecommendationQueryParamsCommon &
  BELocalization;

type FRLocalization = Coordinates & {
  legacyAddressId: number;
};
type RecommendationQueryParamsMALegacy =
  RecommendationQueryParamsRequestCommon & FRLocalization;

export class FakeGenerator {
  static get randomEstimationId(): string {
    const estimationId = faker.string.uuid();
    return estimationId;
  }

  static get randomPrice(): number {
    const price = faker.number.int({ min: 0, max: 1000000 });
    return price;
  }

  static get randomPropertyType(): string {
    const propertyType = faker.helpers.arrayElement(["Apartment", "House"]);
    return propertyType;
  }

  static get randomBEZipcode(): string {
    const zipCode = faker.location.zipCode("####");
    return zipCode;
  }

  static get randomBELocalization(): BELocalization {
    return {
      lat: 51.2593008591088,
      lng: 4.79091201914399,
      zipCode: "6030", // faker.location.zipCode("####"),
    } as BELocalization;
  }

  static get randomFRLocalization(): FRLocalization {
    return {
      lat: 48.889899,
      legacyAddressId: 110299,
      lng: 2.3416758,
    } as FRLocalization;
  }

  static commonQueryParams(
    commonQueryParams: RecommendationQueryParamsRequestCommon
  ): RecommendationQueryParamsCommon {
    commonQueryParams.estimationId ??= this.randomEstimationId;
    commonQueryParams.price ??= this.randomPrice;
    commonQueryParams.propertyType ??= this.randomPropertyType;

    const baseQueryParams = {
      estimationId: commonQueryParams.estimationId,
      price: commonQueryParams.price,
      propertyType: commonQueryParams.propertyType,
    } as RecommendationQueryParamsCommon;
    return baseQueryParams;
  }

  static buildIWBRecommendationEstimationFunnelQueryParams(
    queryParams?: RecommendationQueryParamsRequestIWB
  ): RecommendationQueryParamsIWB {
    queryParams ??= {} as RecommendationQueryParamsRequestIWB;
    if (
      queryParams.lat == undefined ||
      queryParams.lng == undefined ||
      queryParams.zipCode == undefined
    ) {
      const randomBECoordinates = this.randomBELocalization;
      queryParams.lat = randomBECoordinates.lat;
      queryParams.lng = randomBECoordinates.lng;
      queryParams.zipCode = randomBECoordinates.zipCode;
    }
    const baseQueryParams = this.commonQueryParams(
      queryParams as RecommendationQueryParamsRequestCommon
    );

    const response = {
      ...queryParams,
      ...baseQueryParams,
    } as RecommendationQueryParamsIWB;

    return response;
  }

  static buildMALegacyRecommendationEstimationFunnelQueryParams(
    queryParams?: RecommendationQueryParamsRequestMALegacy
  ): RecommendationQueryParamsMALegacy {
    queryParams ??= {} as RecommendationQueryParamsRequestMALegacy;
    if (
      queryParams.lat == undefined ||
      queryParams.lng == undefined ||
      queryParams.legacyAddressId == undefined
    ) {
      const randomFRCoordinates = this.randomFRLocalization;
      queryParams.lat = randomFRCoordinates.lat;
      queryParams.lng = randomFRCoordinates.lng;
      queryParams.legacyAddressId = randomFRCoordinates.legacyAddressId;
    }

    const baseQueryParams = this.commonQueryParams(
      queryParams as RecommendationQueryParamsRequestCommon
    );

    const response = {
      ...queryParams,
      ...baseQueryParams,
    } as RecommendationQueryParamsMALegacy;

    return response;
  }
}

export function validateRecommendationEstimationFunnelIWB(
  response: AxiosResponse<any, any>
): boolean {
  console.log(
    "Execute Estimation Funnel Recommendation IWB response validator"
  );
  describe("Array", function () {
    it("should return agencies", function () {
      expect(response.data).have.property("agencies");
      expect(response.data.agencies).with.lengthOf(20);
    });
  });
  return true;
}

export class BFFTester {
  wlacRequest: Request;
  constructor(request: Request) {
    this.wlacRequest = request;
  }

  async testRecommendationEstimationFunnel(
    brand: Brand,
    queryParams?: RecommendationQueryParamsRequestCommon,
    responseValidatorCallback?: responseValidatorCallbackType
  ) {
    if (brand == Brand.LOGICIMMO || brand == Brand.SELOGER) {
      queryParams =
        FakeGenerator.buildMALegacyRecommendationEstimationFunnelQueryParams(
          queryParams
        );
    } else if (brand == Brand.IMMOWEB) {
      queryParams =
        FakeGenerator.buildIWBRecommendationEstimationFunnelQueryParams(
          queryParams
        );
    }

    responseValidatorCallback ??= validateRecommendationEstimationFunnelIWB;

    console.log(
      chalk.bgWhite.blue.bold(
        `Execute Recommendation for estimation funnel for ${brand}`
      )
    );
    const response = this.wlacRequest.execute({
      path: `/v1/recommendation/estimation_funnel/${brand}`,
      method: "GET",
      queryParams: queryParams,
      validationCallback: responseValidatorCallback,
    });
    return response;
  }
}
