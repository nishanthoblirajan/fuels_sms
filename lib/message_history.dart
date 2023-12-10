import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class MessageHistory extends StatefulWidget {
  const MessageHistory({Key? key}) : super(key: key);

  @override
  _MessageHistoryState createState() => _MessageHistoryState();
}

class _MessageHistoryState extends State<MessageHistory> {
  List<ParseObject> messages = [];
  String searchFrom = '';
  String searchMessage = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final QueryBuilder<ParseObject> queryBuilder =
        QueryBuilder(ParseObject('MessageInfo'))
          ..whereContains('From', searchFrom, caseSensitive: false)
          ..whereContains('Message', searchMessage, caseSensitive: false)
          ..orderByDescending('createdAt')
          ..setLimit(6000);

    final ParseResponse apiResponse = await queryBuilder.query();

    if (apiResponse.success && apiResponse.result != null) {
      setState(() {
        messages = List.from(apiResponse.result);
      });
    } else {
      print('Error fetching data: ${apiResponse.error?.message}');
    }
  }

  Future<void> deleteMessage(String objectId) async {
    final ParseObject message = ParseObject('MessageInfo')..objectId = objectId;
    final ParseResponse response = await message.delete();

    if (response.success) {
      print('Message deleted successfully');
    } else {
      print('Error deleting message: ${response.error?.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message History'),
      ),
      body: Column(
        children: [
          // TextField for 'From' search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchFrom = value;
                    fetchData();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by From',
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchMessage = value;
                  fetchData();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Message',
              ),
            ),
          ),
          // ListView.builder
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final from = message.get<String>('From');
                final msg = message.get<String>('Message');
                final createdAt = message.get<DateTime>('createdAt');
                final objectId = message.objectId;

                return ListTile(
                  title: Text(
                    'From: $from',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Message: $msg'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${DateFormat('MMM dd, yyyy HH:mm').format(createdAt!)}',
                        style: TextStyle(color: Colors.grey),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Call the deleteMessage method when delete button is pressed
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Confirm Deletion'),
                                content: Text(
                                    'Are you sure you want to delete this message?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteMessage(objectId!);
                                      Navigator.of(context).pop();
                                      fetchData(); // Refresh the data after deletion
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
