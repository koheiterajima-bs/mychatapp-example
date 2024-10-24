# mychatapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 参考サイト
[Firebaseを使ったアプリ概要](https://www.flutter-study.dev/firebase-app/about-firebase-app)

## 学んだこと
- StatefulWidgetとStateだと何が不便か
  - 様々なWidgetが組み合わさったUIになり、状態が複雑になってしまうと管理しきれなくなってしまう
- Providerを使うと何がよいか
  - 親Widgetから子Widgetにデータを受け渡すことができる、データを渡す先は子WidgetであればどこでもOK
- Providerによるデータの受け渡し方法
  - 親WidgetでProvider<T>.value()を使いデータを渡す
  - 子WidgetでProvider<T>()を使いデータを受け取る