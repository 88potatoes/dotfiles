import { JSONFilePreset } from 'lowdb/node'
import { Comment } from '../src/comments/comments.table.ts'
import { Low } from 'lowdb';

interface Data {
  comments: Comment[];
}

// Read or create db.json
const defaultData: Data = { comments: [] }
export const db: Low<Data> = await JSONFilePreset<Data>('db.json', defaultData)
