# ƴͼ �� Pintu for iPhone

[![Build iPhone App](https://github.com/GuangzhiSu/image_collage/actions/workflows/ios.yml/badge.svg)](https://github.com/GuangzhiSu/image_collage/actions/workflows/ios.yml)

һ���ο���ͼ����ƴͼ�������̵�ԭ�� iPhone App��ʹ�� SwiftUI + UIKit ������iOS 17.0 �����ϣ��޵���������ʱ�������޹�桢��ˮӡ��������ͼ��Ϊ����Ŀ�Լ���ʵ�֡�

## ��ʵ��

- ϵͳ���ѡͼ����ѡ��˳���� 1�C12 ����Ƭ���ɼ������ӡ�֧��ϵͳ�ɽ���� JPEG��PNG��HEIC �Ⱦ�̬��Ƭ��Live Photo ʹ�þ�̬֡��
- ������Ƭ�������������ģ�壺��ͼ��Сͼ����������/�������С����������ÿ��ģ��ǡ��ʹ��ȫ����Ƭ��
- ����������3:4��1:1��4:3��9:16��16:9��4:5��2:3��
- ����ͼ������ƴ�ӣ�����Ƭԭʼ�������С�
- ���Ԥ���е���Ƭ���϶���˫ָ���š��������š�90�� ��ת���������ã�ȡ�������޸ĵ�ǰ�ü���
- ��������ͼ��ǰ�ơ����ơ��Ƴ���ʹ�üӺż���ѡͼ��
- ��ࡢԲ�ǡ����ֱ�����ɫ��
- ���� JPEG����� 2048 / 3072 / 4096 ���أ�ֱ�ӱ��浽��ᣬ��ϵͳ�������洢���ļ���
- Ȩ�ޱ��ܾ�ʱ�ṩ������ڣ�iCloud ���ء���ʽ��֧�ֵȵ���������ȷ��ʾ��
- ����ʾ�������ڲ���ȡ������������á�

��Ƭֻ���豸�ϴ�����û�з��������˺Ż��ϴ���ϵͳѡͼ��ֻ�ṩ��ѡ�е���Ƭ������ʱ������������Ƭ����Ȩ�ޡ������ļ������Ӧ�õ���ʱĿ¼�����汾���ṩ�������Ĳݸ�ָ����˳�ǰ�뱣��ƴͼ��

## Windows �û������� iPhone ��װ��

1. �� [Actions �� Build iPhone App](https://github.com/GuangzhiSu/image_collage/actions/workflows/ios.yml)��
2. ѡ������һ����ɫ�ɹ���¼�����û�м�¼���ɵ�� **Run workflow**��
3. ���������ҳ��ײ��� **Artifacts** ������ **Pintu-iPhone-unsigned**����ѹ�õ� `Pintu-unsigned.ipa`������ Artifact ��Ҫ��¼ GitHub��
4. �� Windows ʹ�� Sideloadly ���������úõ� AltStore / SideStore Ϊ IPA ǩ�����ٰ�װ�� iPhone��

**����δǩ�� IPA������ֱ�����ֻ��ϵ����װ��** GitHub Actions ����Ҫ��� Apple ID��������֤������룻�豸ǩ�������ڱ����Ĳ��ع�������ɡ���ѵĸ���ǩ��ͨ����Ҫ������ǩ��TestFlight / App Store ������Ҫ�������� Apple Developer ֤��ͷ������̣�����Ŀ���Զ��������̵ꡣ

��Ҫ�ֹ��²��ƴ�� Artifact ���� URL����� Actions ����ҳ����룬����ʧЧ���Ӻ� 404��

ÿ�����ʹ��뵽 `main` �����Զ����в��Բ����� IPA����һ������ **Pintu-preview-and-tests** ����ģ����Ԥ��ͼ��������־�Ͳ��Խ����IPA ���� 30 �죬���ں��������й������ɡ�

## macOS / Xcode ����

```sh
brew install xcodegen
python3 scripts/generate_assets.py
xcodegen generate
open Pintu.xcodeproj
```

�� Xcode �� Signing & Capabilities ��ѡ����� Team �󣬿���ֱ�����е� iPhone��ģ��������ǩ���������� `project.yml` ΪԴ��Xcode ���̡�Info.plist �� AppIcon �������ɲ����д���������Ҫ��װ Swift Package �� CocoaPods ������

## �ṹ����֤

| �ļ� | ���� |
| --- | --- |
| `CollageGeometry.swift` | 1�C12 �Ų��֡������ߴ硢��ͼ�Ͳü����� |
| `PhotoStore.swift` | ϵͳѡͼ��ԭ�ļ���ʱ�洢��EXIF ����������ͼ |
| `CollageModel.swift` | �༭״̬��˳�򡢵��롢�������� |
| `ContentView.swift` / `CropEditor.swift` | �༭����͵�ͼ�ü� |
| `CollageRenderer.swift` | Ԥ��ͬԴ�ĸ�����ơ����д�� |
| `CollageAppTests/CollageTests.swift` | ģ�����������ص����޿հײü������˱������������ز��� |
| `.github/workflows/ios.yml` | ģ�������ԡ���ͼ����ǩ����������� IPA ��� |

����ʱ���Ŷ�ȡ�ϴ�ͼ�񣬲�ͬʱ���� 12 ��ȫ�ֱ���ԭͼ����� 4096 ָ����ͼƬ�ĳߴ磬����֤�ͷֱ���ԭͼ���Ŵ������ϸ�ڡ���ͼ��Ƭ�ܶ�ʱ����������ƣ�����ͼ����Ч�ֱ��ʻή�͡�

������գ��״�ѡͼ��iCloud ԭͼ���ء�HEIC/��ת��Ƭ��1/3/12 ��ģ�塢�ü�ȡ����ȷ�ϡ�������ɾ��������ࡢ��ᱣ������/�ܾ��������롰�洢���ļ������Զ����Բ��������Ȩ�޺Ͳ�����֤��
