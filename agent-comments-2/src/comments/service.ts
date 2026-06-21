import { CommentEntity, CommentStatus, CreateCommentEntityInput, OptionalField } from "./comments.domain.ts";
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

  async getAllComments(filter?: { file?: string; status?: CommentStatus }): Promise<CommentEntity[]> {
    return this.commentsRepo.queryComments(filter ?? {})
  }

  async addComment(comment: OptionalField<CreateCommentEntityInput, "status">): Promise<CommentEntity> {
    return this.commentsRepo.createComment({ status: CommentStatus.Active, ...comment })
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
