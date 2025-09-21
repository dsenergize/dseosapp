import 'package:flutter/material.dart';
import 'package:dseos/theme.dart';

class PlantCard extends StatefulWidget {
  final String plantName;
  final String capacity;
  final VoidCallback onTap;

  const PlantCard({
    Key? key,
    required this.plantName,
    required this.capacity,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends State<PlantCard> {
  bool _isToggled = true;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 32, color: kPrimaryColor),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Switch(
                      value: _isToggled,
                      onChanged: (value) {
                        setState(() {
                          _isToggled = value;
                        });
                      },
                      activeColor: kPrimaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.plantName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.capacity} kW',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
