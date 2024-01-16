import 'dart:convert';
import 'dart:math';
import 'package:echoes_ai/utils/chat_manager.dart';
import 'package:echoes_ai/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatManager chatManager = ChatManager();

  @override
  void initState() {
    chatManager.initializeWebSocket();
    chatManager.channel.stream.listen((event) {
      chatManager.onMessageReceived(event);
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MyDrawer(
        drawer: Material(
          child: Container(
            color: const Color(0xff24283b),
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 100, top: 100),
              itemCount: 20,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    'Item ${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              "Echoes AI",
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
          ),
          body: Chat(
            messages: chatManager.messages,
            onSendPressed: _handleSendPressed,
            onAttachmentPressed: _handleImageSelection,
            showUserAvatars: false,
            showUserNames: true,
            user: chatManager.user,
            theme: const DefaultChatTheme(
                backgroundColor: Colors.black,
                inputBorderRadius: BorderRadius.zero,
                receivedMessageBodyTextStyle: TextStyle(color: Colors.white),
                secondaryColor: Color(0xFF1c1c1c),
                attachmentButtonIcon: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                ),
                inputBackgroundColor: Color(0xFF1c1c1c),
                inputContainerDecoration: BoxDecoration(border: Border()),
                seenIcon: Text(
                  'read',
                  style: TextStyle(fontSize: 10.0),
                )),
          ),
        ));
  }

  void _handleSendPressed(types.PartialText message) {
    if (!chatManager.isLoading) {
      final textMessage = types.TextMessage(
        author: chatManager.user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: message.text,
      );
      chatManager.addMessage(textMessage);
      setState(() {});
    }
  }

  // onImageSelection() {
  //   Navigator.of(context).push(MaterialPageRoute(
  //     builder: (context) => ImagePromptBottomSheet(
  //         onCancel: () => Navigator.of(context).pop(),
  //         onSubmit: (prompt, image) async {
  //           late XFile? img;
  //           img = image;
  //           if (img != null) {
  //             final bytes = await img.readAsBytes();
  //             final enbytes = base64Encode(bytes);

  //             final image = await decodeImageFromList(bytes);
  //             final message = types.ImageMessage(
  //               author: chatManager.user,
  //               createdAt: DateTime.now().millisecondsSinceEpoch,
  //               height: image.height.toDouble(),
  //               id: const Uuid().v4(),
  //               name: img.name,
  //               size: bytes.length,
  //               uri: img.path,
  //               width: image.width.toDouble(),
  //             );
  //             print(message);
  //             chatManager.addMessage(message, enbytes);
  //           }
  //         }),
  //   ));
  // }

  bool isImagePickerActive = false;

  void _handleImageSelection() async {
    // Check if the image picker is already active
    if (isImagePickerActive) {
      return;
    }

    // Set the flag to indicate that the image picker is active
    isImagePickerActive = true;

    try {
      // final image = AssetImage('assets/images/tajmahal-7869968_1280.jpg');
      final result = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1440,
      );
      print(result);

      if (result != null) {
        final bytes = await result.readAsBytes();
        final enbytes = base64Encode(bytes);

        final image = await decodeImageFromList(bytes);
        final message = types.ImageMessage(
          author: chatManager.user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          height: image.height.toDouble(),
          id: const Uuid().v4(),
          name: result.name,
          size: bytes.length,
          uri: result.path,
          width: image.width.toDouble(),
        );
        print(message);
        chatManager.addMessage(message, enbytes);
      }
    } catch (e) {
      log("Error picking image: $e" as num);
    } finally {
      // Reset the flag after image picking is done
      isImagePickerActive = false;
    }
  }
}

// class ImagePromptBottomSheet extends StatefulWidget {
//   final Function(String, XFile?) onSubmit;
//   final Function() onCancel;

//   const ImagePromptBottomSheet({
//     Key? key,
//     required this.onSubmit,
//     required this.onCancel,
//   }) : super(key: key);

//   @override
//   State<ImagePromptBottomSheet> createState() => _ImagePromptBottomSheetState();
// }

// class _ImagePromptBottomSheetState extends State<ImagePromptBottomSheet> {
//   @override
//   Widget build(BuildContext context) {
//     final TextEditingController promptController = TextEditingController();
//     XFile? imageFile;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () async {
//               final ImagePicker picker = ImagePicker();
//               imageFile = await picker.pickImage(source: ImageSource.gallery);
//               setState(() {});
//             },
//             child: const Text('Pick Image'),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: promptController,
//             decoration: const InputDecoration(labelText: 'Enter Prompt'),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               TextButton(
//                   onPressed: widget.onCancel, child: const Text('Cancel')),
//               const SizedBox(width: 16),
//               ElevatedButton(
//                 onPressed: () =>
//                     widget.onSubmit(promptController.text, imageFile),
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
