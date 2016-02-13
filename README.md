# GUIActivityIndicatorView

## Demo

![Demo](https://raw.githubusercontent.com/ronyfadel/GUIActivityIndicatorView/master/Demo.gif "Demo")

## Usage

- git clone https://github.com/ronyfadel/GUIActivityIndicatorView.git
- run example app

``` objc
GUIActivityIndicatorView *activityIndicatorView = [[GUIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];

[self.view addSubview:activityIndicatorView];

// To start animating
[activityIndicatorView startAnimating];

// To hide view when stopped
activityIndicatorView.hidesWhenStopped = YES;

// To stop animating
[activityIndicatorView stopAnimating];

// To check if view is animating or not
activityIndicatorView.isAnimating;

```
Xib and StoryBoard supported

## Contact

* Rony Fadel
* [@ronyfadel](http://www.twitter.com/ronyfadel/)

## License

GUIActivityIndicatorView is available under the MIT license. See the LICENSE file for more info.

