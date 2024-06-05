# Overview #
This code is just a collection of important snippets, and the whole solution is working in production at my job, which I can't share.

## The problem ##
Flutter's standard http library has problems working with cookies on mobile and the browser because the browsers dont allow flutter to set the cookies.

See: https://www.reddit.com/r/flutterhelp/comments/15fxgl2/managing_session_cookie_in_flutterweb_app/

## The solution ##
The solution is to use browserclient for the flutter web build and normal client for the mobile build. To do that you need to import the respective classes conditionally, and very carefully because you cannot import browser client in mobile build or else it wont compile.

I also built an interceptor on top of it, which has 3 example interceptors, and you can add more along according to your needs. 

## Usage ##
To use it, instead of importing the http library from the standard library, just import the custom 'HttpClient' that we built from 'http_client.dart'. It supports all the methods of a standard http request from the standard library, and is just a wrapper built on top of it.

```dart
//imported from our custom wrapper
final httpClient = HttpClient();

final response = await httpClient.post(
    Uri.parse('$url/login'),
    headers: {
    'Content-Type': 'application/json; charset=UTF-8',
    },
    body:json.encode({
        'email': username,
        'password': password,
    }),
);
```
```dart
// get request
final httpClient = HttpClient();
final response = await httpClient.get(Uri.parse('$url/airport/all'));
...
```
What if I am using tokens & cookies? 
>Use or build a custom interceptor from the file 'interceptor_contract.dart'. It takes care of silent token authentication, without having to take care of it explicitly in each request.

## My Backend ##
I use JWTs stored in cookies on the browser, and custom token handler on mobile. I use cookie-parser for the cookie building and parsing.
```ts
const signIn = async (req: Request, res: Response, next: NextFunction) => {
    const payload = getAllParametersFromRequest(req);
    const data = await authService.signinService(payload);
    res
        .cookie("token", data.token, {
            path: "/",
            // expires: expires, //havent tried it yet
            httpOnly: true,
            //   signed: true, //works only with https. currently building locally, so commented out
            // sameSite: "none", //can change this in prod
            //   secure: true // again, https only

        }).cookie("refreshToken", data.refreshToken, {
            path: "/",
            httpOnly: true,
            //expires: expires,
            // signed: true,
            // sameSite: "none",
            // secure: true
        })
        .status(200).json(data);

  return;
}
```