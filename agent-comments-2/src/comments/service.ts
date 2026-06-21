import { CommentRepo } from "./repo.ts"

export class CommentService {
  private commentsRepo: CommentRepo

  constructor({
    commentsRepo
  }: {
    commentsRepo: CommentRepo
  }) {
    this.commentsRepo = commentsRepo
  }

  getAllComments(): Comment[] {
    this.commentsRepo.getAllComments()
  }
  addComment(comment: Comment): void {
    this.db.comments.push(comment)
  }
  deleteComment(id: string): void {
    this.db.comments = this.db.comments.filter((c) => c.id !== id)
  }
  resolveComment(id: string): void {
    const comment = this.db.comments.find((c) => c.id === id)
    if (!comment) return
    comment.status = "resolved"
    comment.updatedAt = new Date().toISOString()
  }
  unresolveComment(id: string): void {
    const comment = this.db.comments.find((c) => c.id === id)
    if (!comment) return
    comment.status = "active"
    comment.updatedAt = new Date().toISOString()
  }
}
