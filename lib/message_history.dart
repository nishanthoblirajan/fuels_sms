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

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final QueryBuilder<ParseObject> queryBuilder =
        QueryBuilder(ParseObject('MessageInfo'))
          ..whereContains('From', searchFrom, caseSensitive: false)
          ..orderByDescending('createdAt');

    final ParseResponse apiResponse = await queryBuilder.query();

    if (apiResponse.success && apiResponse.result != null) {
      setState(() {
        messages = List.from(apiResponse.result);
      });
    } else {
      print('Error fetching data: ${apiResponse.error?.message}');
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
          // ListView.builder
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final from = message.get<String>('From');
                final msg = message.get<String>('Message');
                final createdAt = message.get<DateTime>('createdAt');

                return ListTile(
                  title: Text(
                    'From: $from',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Message: $msg'),
                  trailing: Text(
                    '${DateFormat('MMM dd, yyyy HH:mm').format(createdAt!)}',
                    style: TextStyle(color: Colors.grey),
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
