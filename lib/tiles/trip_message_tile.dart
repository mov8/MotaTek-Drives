import 'package:flutter/material.dart';
import '/models/other_models.dart';
import 'package:intl/intl.dart';

class TripMessageTile extends StatefulWidget {
  final TripMessage message;
  final Function(int) onEdit;
  final Function(int) onSelect;

  final int index;
  const TripMessageTile({
    super.key,
    required this.index,
    required this.message,
    required this.onEdit,
    required this.onSelect,
  });

  @override
  State<TripMessageTile> createState() => _TripMessageTileState();
}

class _TripMessageTileState extends State<TripMessageTile> {
  DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => setState(() => widget.onSelect(widget.index)),
      title: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.message.sender,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '${widget.message.carColour} ${widget.message.manufacturer} ${widget.message.model}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Reg No ${widget.message.registration}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "Message",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextFormField(
                  readOnly: true,
                  initialValue: widget.message.message,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  //  decoration: InputDecoration(
                  //    border: OutlineInputBorder(
                  //      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  //    ),
                  // ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
