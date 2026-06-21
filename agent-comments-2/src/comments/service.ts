import { CommentEntity, CommentStatus, CreateCommentEntityInput } from "./comments.domain.ts";
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

  async getAllComments(): Promise<CommentEntity[]> {
    return this.commentsRepo.getAllComments()
  }

  async addComment(comment: CreateCommentEntityInput): Promise<CommentEntity> {
    return this.commentsRepo.createComment(comment)
  }
  async deleteComment(id: string): Promise<void> {
    this.commentsRepo.deleteComment(id)
  }
  async resolveComment(id: string): Promise<CommentEntity> {
    return this.commentsRepo.updateComment({ id, status: CommentStatus.Resolved })
  }
  async unresolveComment(id: string): Promise<CommentEntity> {
    return this.commentsRepo.updateComment({ id, status: CommentStatus.Active })
  }
}
