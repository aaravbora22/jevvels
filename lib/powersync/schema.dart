// schema.dart
import 'package:powersync/powersync.dart';
import 'package:powersync_attachments_helper/powersync_attachments_helper.dart';

final schema = Schema([
  const Table('categories', [
    Column.text('name'),
  ]),
  const Table('shops', [
    Column.text('name'),
  ]),
  const Table('bill_images', [
    Column.text('path'),
  ]),
  const Table('item_images', [
    Column.text('path'),
  ]),
  const Table('jewelry_items', [
    Column.text('user_id'),
    Column.text('category_id'),
    Column.text('shop_id'),
    Column.real('total_weight'),
    Column.text('bill_images_id'),
    Column.text('item_images_id'),
    Column.text('notes'),
  ]),
  const Table('metals', [
    Column.text('jewelry_item_id'),
    Column.real('weight'),
    Column.text('type'),
    Column.integer('karat'),
  ]),
  const Table('pricing_details', [
    Column.text('jewelry_item_id'),
    Column.real('total_price'),
    Column.real('making_cost'),
    Column.real('precious_metals_rate'),
  ]),

  // adds the local ‘attachments_queue’ table needed by the helper
  AttachmentsQueueTable(),
]);
