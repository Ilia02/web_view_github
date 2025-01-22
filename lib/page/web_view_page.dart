import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum MenuOptions {
  clearCache,
  clearCookies,
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _webController;

  @override
  void initState() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://github.com/login'))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            log('Страница полностью загружена');
            if (url.contains('https://github.com/login')) {
              if (isSubmitting) {
                _webController
                    .loadRequest(Uri.parse('https://github.com/login'));
                isSubmitting = false;
              }
            }
          },
          onProgress: (progress) {
            this.progress = progress / 100;
            setState(() {});
          },
          onPageStarted: (url) {
            log('Новый сайт: $url');
            // if (url.contains('https://flutter.dev')) {
            //   Future.delayed(const Duration(microseconds: 300), () {
            //     _webController.runJavascriptReturningResult(
            //       "document.getElementsByTagName('footer')[0].style.display='none'",
            //     );
            //   });
            // }
          },
        ),
      );
    super.initState();
  }

  double progress = 0;

  late bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _webController.canGoBack()) {
          _webController.goBack();
        } else {
          log('Нет записи в истории');
        }

        // Stay App
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WebView'),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () async {
                if (await _webController.canGoBack()) {
                  _webController.goBack();
                } else {
                  log('Нет записи в истории');
                }
                return;
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () async {
                if (await _webController.canGoForward()) {
                  _webController.goForward();
                } else {
                  log('Нет записи в истории');
                }
                return;
              },
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () => _webController.reload(),
            ),
            PopupMenuButton<MenuOptions>(
              onSelected: (value) {
                switch (value) {
                  case MenuOptions.clearCache:
                    _onClearCache(_webController, context);
                    break;
                  case MenuOptions.clearCookies:
                    _onClearCookies(context);
                    break;
                }
              },
              itemBuilder: (context) => <PopupMenuItem<MenuOptions>>[
                const PopupMenuItem(
                  value: MenuOptions.clearCache,
                  child: Text('Удалить кеш'),
                ),
                const PopupMenuItem(
                  value: MenuOptions.clearCookies,
                  child: Text('Удалить Cookies'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              color: Colors.red,
              backgroundColor: Colors.black,
            ),
            Expanded(
              child: WebViewWidget(
                controller: _webController,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.next_plan, size: 32),
          onPressed: () async {
            const email = 'Lakeev.2017@list.ru';
            const pass = '*********';

            _webController.runJavaScriptReturningResult(
              "document.getElementById('login_field').value='$email'",
            );

            _webController.runJavaScriptReturningResult(
              "document.getElementById('password').value='$pass'",
            );

            await Future.delayed(const Duration(seconds: 1));
            isSubmitting = true;
            await _webController.runJavaScriptReturningResult(
              "document.forms[0].submit()",
            );
            // final currentUrl = await _webController.currentUrl();
            // log('Предыдущий сайт: $currentUrl');
            // _webController.loadUrl('https://www.youtube.com');
            // _webController.runJavascriptReturningResult(
            //   "document.getElementsByTagName('footer')[0].style.display='none'",
            // );
          },
        ),
      ),
    );
  }

  void _onClearCookies(BuildContext context) async {
    final bool hadCookies = await WebViewCookieManager().clearCookies();
    String message = 'Cookies удалены';
    if (!hadCookies) {
      message = 'Cookies все были очищены';
    }
    //  https://docs.flutter.dev/deployment/android#reviewing-the-build-configuration
    if (!mounted) return; // Проверяем, что виджет смонтирован
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onClearCache(WebViewController controller, BuildContext context) async {
    await _webController.clearCache();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Кеш очищен')),
    );
  }
}
