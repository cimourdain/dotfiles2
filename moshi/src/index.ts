import axios from 'axios';
import FormData from 'form-data';
import { parse } from 'node-html-parser';



function parseResponse(html_str: string): RandomBELocation {
  const html = parse(html_str);
  const zipCodeTag = html
    .getElementsByTagName('p')
    .find((tag) => tag.textContent.startsWith('Postcode:'));
  const zipCode = zipCodeTag.rawText.split(':')[1].trim();

  const gmapLink = html
    .getElementsByTagName('a')
    .find(
      (tag) =>
        tag.hasAttribute('href') &&
        tag.getAttribute('href').startsWith('https://maps.google.com/')
    );
  const coordinatesQueryArg = gmapLink
    .getAttribute('href')
    .split('&')
    .find((urlPart) => urlPart.startsWith('cbll='));
  const coordinatesTxt = coordinatesQueryArg.split('=')[1];
  const lat = Number(coordinatesTxt.split(',')[0]);

  const lng = Number(coordinatesTxt.split(',')[1]);
  return {
    zipCode,
    lat,
    lng,
  } as RandomBELocation;
}

const form = new FormData();
form.append('number', '1');
form.append('state', 'belgium');
form.append('_token', '29iG9OPMq86SWqjDMgHeE3xC8vde3JCUAkjD8fft');

axios
  .post('https://www.generatormix.com/random-address-in-belgium', form, {
    headers: {
      ...form.getHeaders(),
      'User-Agent':
        'Mozilla/5.0 (X11; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0',
      Accept: 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language': 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
      'Accept-Encoding': 'gzip, deflate, br, zstd',
      'X-CSRF-TOKEN': '29iG9OPMq86SWqjDMgHeE3xC8vde3JCUAkjD8fft',
      'X-Requested-With': 'XMLHttpRequest',
      'Content-Type':
        'multipart/form-data; boundary=---------------------------301544831230640875073335463982',
      Origin: 'https://www.generatormix.com',
      DNT: '1',
      'Sec-GPC': '1',
      Connection: 'keep-alive',
      Referer:
        'https://www.generatormix.com/random-address-in-belgium?number=1',
      Cookie:
        'XSRF-TOKEN=eyJpdiI6Im9LallPQ1lXSlNjY3JiY1wvNGRuYUZRPT0iLCJ2YWx1ZSI6IlZJMW9yVlhwb1I4UmsyaFdSTkFPb3dWMXdqZ2RVcE8wSWxNXC92bG8rdkxQK0tHUDVYVURVMUlZb3doM01EUnBFIiwibWFjIjoiMjI3MTM2YjNhNjUyNWQxOTE3ZGZiNmE2OTA2ZTc0ODk3Y2ZiNWU4ZDY3YWM0N2YwZmZhOTI0NTdjZjAyMjdkNyJ9; laravel_session=eyJpdiI6InY3UFNNRWNaZlwveUZjUXNKM1lZWlZnPT0iLCJ2YWx1ZSI6Img2R3hvQWhoV0g1dzVQNU1RUk1ISWJoTUoyMXY1OVB0YWpRMWJnbDdDeEtMRktcL3QyYStRbkI2Nm1JSytkVmRIIiwibWFjIjoiMmFjYjQ0ODZjZjVhOWFhZWNhOTNlYjQ4MzA0YjcxMjgzYmM0M2FiNDZkMjNlZDZjMzgxZjIxMzkwZjEwYTg1ZCJ9; ezoictest=stable; ez-consent-tcf=CQAF9jAQAF9jAErAJJENA4EsAP_gAEPgAAwIKRNV_H__bW1r8X73aftkeY1P9_j77sQxBhfJE-4FzLvW_JwXx2ExNA36tqIKmRIEu3bBIQNlHJDUTVCgaogVryDMakWcoTNKJ6BkiFMRO2dYCF5vmwtj-QKY5vr993dx2D-t_dv83dzyz4VHn3a5_2e0WJCdA58tDfv9bROb-9IPd_58v4v8_F_rE2_eT1l_tevp7D9-cts7_XW-9_fff79Ll9-mBwUhALMNCogDrIkJCDQMIIEAKgrCAigQAAAAkDRAQAmDAp2BgEusJEAIAUAAwQAgABRkACAAASABCIAIACgQAAQCBQAAgAQDAQAMDAAGACwEAgABAdAhTAggUCwASMyIhTAhCgSCAlsqEEgCBBXCEIs8CCAREwUAAAJABWAAICwWBxJICViQQJcQbQAAEACAQQAVCKTswBBAGbLVXiybRlaQFo-cL3tAAAAA.YAAAAAAAAAAA; ezoab_123686=mod270-c; ezoadgid_123686=-1; ezosuibasgeneris-1=99fb0fc3-4c00-4d7e-43b5-67f25a610b63; active_template::123686=pub_site.1718187688; ezopvc_123686=1',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-origin',
      Priority: 'u=1',
      Pragma: 'no-cache',
      'Cache-Control': 'no-cache',
      TE: 'trailers',
    },
  })
  .then((response) => {
    console.log(response.data.output);
    const randomBeLocation = parseResponse(response.data.output);
    console.log(randomBeLocation);
  })
  .catch((error) => {
    console.error(error);
  });
